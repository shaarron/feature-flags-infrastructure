output "cloudfront_domain_name" {
  description = "Public domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cf.domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cf.id
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted zone ID to use for Route53 alias to CloudFront"
  value       = aws_cloudfront_distribution.cf.hosted_zone_id
}
