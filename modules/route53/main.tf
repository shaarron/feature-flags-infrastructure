terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_route53_zone" "this" {
  name = var.domain_name
}

data "aws_cloudfront_distribution" "cf" {
  for_each = var.sub_domains
  id       = each.value.cf_id
}

resource "aws_route53_record" "cf_records" {
  for_each = var.sub_domains

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_cloudfront_distribution.cf[each.key].domain_name
    zone_id                = data.aws_cloudfront_distribution.cf[each.key].hosted_zone_id
    evaluate_target_health = false
  }
}
