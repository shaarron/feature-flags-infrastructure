terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

# Cache policies
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_acm_certificate" "cf_cert" {
  domain   = var.cert_domain_name
  statuses = ["ISSUED"]

}

# Origin Access Control
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.name_prefix}_${var.origin_access_control_origin_type}_oac"
  description                       = "OAC for ${var.origin_access_control_origin_type}"
  origin_access_control_origin_type = var.origin_access_control_origin_type
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "this" {
  enabled = true
  aliases = var.aliases

  # S3 Origin
  dynamic "origin" {
    for_each = var.s3_origin != null ? [var.s3_origin] : []
    content {
      domain_name              = var.s3_bucket_domain_name
      origin_id                = "s3_origin"
      origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    }
  }

  # Custom Origin
  origin {
    domain_name = var.origin_domain_name
    origin_id   = var.origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.origin_protocol_policy
      origin_ssl_protocols   = toset(var.origin_ssl_protocols)

    }
  }

  default_cache_behavior {
    allowed_methods        = var.default_cache_behavior.allowed_methods
    cached_methods         = var.default_cache_behavior.cached_methods
    target_origin_id       = var.default_cache_behavior.target_origin_id
    viewer_protocol_policy = var.default_cache_behavior.viewer_protocol_policy

    cache_policy_id = var.default_cache_behavior.cache_policy_optimized ? data.aws_cloudfront_cache_policy.caching_optimized.id : data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = var.default_cache_behavior.cache_policy_optimized ? null : "216adef6-5c7f-47e4-b989-5492eafa07d3"
    min_ttl     = null
    default_ttl = null
    max_ttl     = null

  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behavior
    content {
      path_pattern             = ordered_cache_behavior.value.path_pattern
      allowed_methods          = ordered_cache_behavior.value.allowed_methods
      cached_methods           = ordered_cache_behavior.value.cached_methods
      viewer_protocol_policy   = ordered_cache_behavior.value.viewer_protocol_policy
      target_origin_id         = ordered_cache_behavior.value.target_origin_id

      cache_policy_id = ordered_cache_behavior.value.cache_policy_optimized ? data.aws_cloudfront_cache_policy.caching_optimized.id : data.aws_cloudfront_cache_policy.caching_disabled.id
      origin_request_policy_id = ordered_cache_behavior.value.cache_policy_optimized ? null : "216adef6-5c7f-47e4-b989-5492eafa07d3"
      min_ttl     = null
      default_ttl = null
      max_ttl     = null

    }

  }
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.cf_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  default_root_object = var.default_root_object

  tags = {
    Project = var.name_prefix
  }
}
