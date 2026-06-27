variable "domain_name" {
  description = "The domain name for the Route53 hosted zone"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster for Pod Identity association"
  type        = string
}
