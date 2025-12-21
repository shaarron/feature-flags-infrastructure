# cluster variables
variable "name_prefix" {
  description = "Prefix for all resources created by this module"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string

}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string

}

variable "vpc_id" {
  description = "The VPC ID where EKS will be created"
  type        = string
}

variable "subnet_ids" {
  description = "The VPC subnets where the EKS control plane and nodes will reside"
  type        = list(string)
}

variable "node_groups" {
  description = "A map of node group configurations"
  type = map(object({
    node_group_name = string
    instance_types  = list(string)
    capacity_type   = optional(string, "ON_DEMAND")
    scaling_config = object({
      desired_size = number
      min_size     = number
      max_size     = number
    })
    labels = optional(map(string), {})
  }))
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Enable admin permissions for the cluster creator via Access Entries"
  type        = bool
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for envelope encryption of Kubernetes secrets. If null, encryption is not enabled."
  type        = string
}