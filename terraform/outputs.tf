output "cluster_endpoint" {
  description = "value of the EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "SG" {
  description = "Security groups for the EKS cluster"
  value = {
    "cluster_primary_security_group_id" = module.eks.cluster_primary_security_group_id
    "cluster_security_group_id"         = module.eks.cluster_security_group_id
    "node_security_group_id"            = module.eks.node_security_group_id
  }
}

output "cluster_connect" {
  description = "Command to connect to the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

