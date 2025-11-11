project_name = "feature-flags"
aws_region   = "ap-south-1"

# S3
versioning                        = true
block_public_access               = true
force_ssl_policy                  = true
server_side_encryption            = true
s3_force_destroy                  = true
origin_access_control_origin_type = "s3"

# network
vpc_cidrs = "10.0.0.0/16"

default_cache_behavior = {
  allowed_methods        = ["GET", "HEAD"]
  cached_methods         = ["GET", "HEAD"]
  target_origin_id       = "s3_origin"
  viewer_protocol_policy = "redirect-to-https"
  cache_policy_optimized = true
}

ordered_cache_behavior = [{
  path_pattern           = "/flags*"
  allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
  cached_methods         = ["GET", "HEAD"]
  cache_policy_optimized = false
  viewer_protocol_policy = "https-only"
  target_origin_id       = "nlb-origin"
}]