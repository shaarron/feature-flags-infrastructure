output "cluster_endpoint" {
  description = "value of the EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}


output "cluster_connect" {
  description = "Command to connect to the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

