resource "aws_eks_node_group" "main" {
  for_each = var.node_groups
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name_prefix}-${each.value.node_group_name}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    min_size     = each.value.scaling_config.min_size
    max_size     = each.value.scaling_config.max_size
  }

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type

  update_config {
    max_unavailable = 1 # Keep at least 1 node running during updates
  }

  # Critical Dependencies
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  # Avoid Terraform fighting the Auto Scaler
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = {
    Name = "${var.name_prefix}-eks-worker-node"
  }
}