provider "aws" {
  region = var.aws_region
}

data "aws_route53_zone" "this" {
  name = var.domain_name
}

locals {
  nlb_records = { for k, v in var.sub_domains : k => v if v.type == "nlb" }
  cf_records  = { for k, v in var.sub_domains : k => v if v.type == "cloudfront" }
}

# NLB lookup
data "aws_lb" "nlb" {
  for_each = local.nlb_records
  name     = each.value.nlb_name
}

# CloudFront lookup
data "aws_cloudfront_distribution" "cf" {
  for_each = local.cf_records
  id       = each.value.cf_id
}

# NLB records
resource "aws_route53_record" "nlb_records" {
  for_each = local.nlb_records

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.nlb[each.key].dns_name
    zone_id                = data.aws_lb.nlb[each.key].zone_id
    evaluate_target_health = false
  }
}

# CloudFront records
resource "aws_route53_record" "cf_records" {
  for_each = local.cf_records

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_cloudfront_distribution.cf[each.key].domain_name
    zone_id                = data.aws_cloudfront_distribution.cf[each.key].hosted_zone_id
    evaluate_target_health = false
  }
}