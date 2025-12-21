# Get the identity of the caller cluster creator
data "aws_caller_identity" "current" {}

# Create an Access Entry for the cluster creator
resource "aws_eks_access_entry" "cluster_creator" {
  count = var.enable_cluster_creator_admin_permissions ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

# Give the caller's principal admin access to the cluster
resource "aws_eks_access_policy_association" "admin" {
  count = var.enable_cluster_creator_admin_permissions ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_caller_identity.current.arn

  access_scope {
    type = "cluster"
  }
}