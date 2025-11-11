variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "force_destroy" {
  description = "Force destroy the bucket and all its contents"
  type        = bool
  default     = true
}

variable "versioning" {
  description = "Enable versioning"
  type        = bool
}

variable "block_public_access" {
  description = "Block public access to the bucket"
  type        = bool
  default     = true
}

variable "force_ssl_policy" {
  description = "Force SSL for bucket access"
  type        = bool
}

variable "server_side_encryption" {
  description = "Enable server-side encryption"
  type        = bool
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution to allow access"
  type        = string
  default     = ""
}