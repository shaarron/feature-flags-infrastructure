variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
}

variable "terraform_backend" {
  description = "Name of the S3 bucket for Terraform state backend"
  type        = string
}
