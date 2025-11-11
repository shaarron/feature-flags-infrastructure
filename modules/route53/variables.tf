variable "aws_region" {
  type = string
}

variable "domain_name" {
  description = "The domain name for the Route53 hosted zone"
  type        = string
}

variable "sub_domains" {
  description = "Map of subdomains and their target types"
  type = map(object({
    type     = string           # "nlb" or "cloudfront"
    nlb_name = optional(string) # if type = "nlb"
    cf_id    = optional(string) # if type = "cloudfront"
  }))
}
