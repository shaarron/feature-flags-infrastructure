variable "aws_region" {
  type = string
}

variable "domain_name" {
  description = "The domain name for the Route53 hosted zone"
  type        = string
}

variable "sub_domains" {
  description = "Map of subdomains to their CloudFront distribution IDs"
  type = map(object({
    cf_id = string
  }))
}
