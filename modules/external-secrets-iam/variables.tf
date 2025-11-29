variable "region" {
  description = "AWS Region"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC Provider (e.g., module.eks.oidc_provider_arn)"
  type        = string
}

variable "oidc_provider" {
  description = "The OIDC Provider URL (without https://)"
  type        = string
}