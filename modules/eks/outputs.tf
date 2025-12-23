output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS control plane"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "The cluster kubernetes version"
  value = aws_eks_cluster.this.version
}

output "cluster_oidc_issuer_url" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for IRSA"
  value = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider" {
  description = "The URL of the OIDC Provider for IRSA without the https:// prefix"
  value = local.oidc_url_short
}

output "vpc_cni_iam_role_arn" {
  description = "The ARN of the IAM role for the VPC CNI IRSA"
  value       = aws_iam_role.vpc_cni_irsa.arn
}