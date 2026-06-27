variable "region" {
  description = "AWS Region"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster for Pod Identity association"
  type        = string
}
