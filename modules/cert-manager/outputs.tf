output "role_arn" {
  value = aws_iam_role.cert_manager_dns01.arn
}

output "hosted_zone_id" {
  value = data.aws_route53_zone.this.zone_id
}