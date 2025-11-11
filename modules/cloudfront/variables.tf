variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "origin_access_control_origin_type" {
  description = "Origin type for the Origin Access Control: s3, lambda, media-store"
  type        = string
}

variable "s3_origin" {
  description = "Configuration for an S3 origin"
  type        = string
}

variable "s3_bucket" {
  description = "The S3 bucket to be used as an origin"
  type        = any
}

variable "origin_domain_name" {
  type    = string
  default = ""
}

variable "origin_id" {
  type    = string
  default = "nlb-origin"
}

variable "origin_protocol_policy" {
  description = "Protocol policy for the custom origin"
  type        = string
  default     = "https-only"
}

variable "origin_ssl_protocols" {
  description = "SSL protocols for the custom origin"
  type        = list(string)
  default     = ["TLSv1.2"]
}

variable "default_cache_behavior" {
  description = "Defines the fallback cache behavior applied to all requests that don’t match a specific path pattern (required)."
  type = object({
    target_origin_id       = string
    allowed_methods        = list(string)
    cached_methods         = list(string)
    viewer_protocol_policy = string
    cache_policy_optimized = bool # use the optimized cache policy (true) or caching disabled (false).
  })
}

variable "ordered_cache_behavior" {
  description = "Defines additional path-based cache behaviors, evaluated in order before the default behavior (optional)."
  type = list(object({
    target_origin_id       = string
    allowed_methods        = list(string)
    cached_methods         = list(string)
    viewer_protocol_policy = string
    path_pattern           = string
    cache_policy_optimized = bool # use the optimized cache policy (true) or caching disabled (false).
  }))
  default = []
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy for the CloudFront distribution"
  type        = string
  default     = "redirect-to-https"
  validation {
    condition     = contains(["allow-all", "https-only", "redirect-to-https"], var.viewer_protocol_policy)
    error_message = "Viewer protocol policy must be one of: allow-all, https-only, redirect-to-https."
  }
}

variable "geo_restriction_type" {
  description = "Type of geo restriction for CloudFront distribution"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Geo restriction type must be one of: none, whitelist, blacklist."
  }
}

variable "use_cloudfront_default_certificate" {
  description = "Whether to use CloudFront default certificate"
  type        = bool
  default     = true
}

variable "cert_domain_name" {
  description = "Domain name for the ACM certificate in us-east-1"
  type        = string
}

variable "default_root_object" {
  description = "Default root object for the CloudFront distribution"
  type        = string
  default     = "index.html"

}

variable "aliases" {
  description = "List of domain names (CNAMEs) to associate with the CloudFront distribution"
  type        = list(string)
  default     = []

}