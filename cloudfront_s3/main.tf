data "aws_caller_identity" "current" {}

# Cache policies
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_acm_certificate" "cf" {
  provider          = aws.us_east_1
  domain            = var.cert_domain_name
  statuses    = ["ISSUED"]
  most_recent = true

}

# S3 bucket for static content
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket

  lifecycle {
    prevent_destroy = false
  }
  force_destroy = true

  tags = {
    Name        = var.s3_bucket
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.project_name}_s3_oac"
  description                       = "OAC for S3 bucket access - ${var.environment}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cf" {
  enabled = true
  depends_on = [aws_s3_bucket.s3_bucket]

  # Origin 1: S3 Bucket
  origin {
    domain_name              = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    origin_id                = "s3_origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # Origin 2: Load Balancer (NLB)
  origin {
    domain_name = var.nlb_domain
    origin_id   = "alb_origin"
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only" 
        origin_ssl_protocols   = ["TLSv1.2"]
  }
  }

  # Default behavior for S3
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3_origin"
    viewer_protocol_policy = var.viewer_protocol_policy    
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  # Behavior for NLB
  ordered_cache_behavior {
    path_pattern           = "/flags*"
    target_origin_id       = "alb_origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET","HEAD"]

   cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
    }
  }
  aliases = [var.domain_name]

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.cf.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  default_root_object = "index.html"
  comment             = var.cloudfront_comment

  tags = {
    Name        = var.cloudfront_distribution_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# S3 Bucket Policy to allow CloudFront access
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowCloudFrontOAC"
        Effect   = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }                        
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.s3_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cf.arn
          }
        }
      }
    ]
  })
}
