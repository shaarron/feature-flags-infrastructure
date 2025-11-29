output "s3_bucket" {
  value = aws_s3_bucket.this.id
}

output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.this.bucket_regional_domain_name
}