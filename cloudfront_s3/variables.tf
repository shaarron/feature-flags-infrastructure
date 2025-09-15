variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "s3_bucket" {
  description = "Name of the S3 bucket for frontend static content"
  type        = string
}

variable "nlb_domain" {
  description = "Domain name of the Network Load Balancer for API requests"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "cloudfront_comment" {
  description = "Comment for the CloudFront distribution"
  type        = string
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy for the default cache behavior"
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

variable "cloudfront_distribution_name" {
  description = "Name for the CloudFront distribution"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the CloudFront distribution"
  type        = string
}

variable "cert_domain_name" {
  description = "Domain name for the ACM certificate (e.g., *.example.com)"
  type        = string
  
}