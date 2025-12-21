terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

data "aws_route53_zone" "this" {
  name = var.domain_name
}

locals {
  nlb_records = { for k, v in var.sub_domains : k => v if v.type == "nlb" }
  cf_records  = { for k, v in var.sub_domains : k => v if v.type == "cloudfront" }
}

resource "aws_route53_record" "nlb_records" {
  for_each = local.nlb_records

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.nlb_hostname
    zone_id                = var.nlb_zone_id
    evaluate_target_health = false
  }
}
data "aws_cloudfront_distribution" "cf" {
  for_each = local.cf_records
  id       = each.value.cf_id
}

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
