resource "aws_kms_key" "eks" {
  count                   = var.kms_key_arn == null ? 1 : 0
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

locals {
  final_kms_key_arn = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.eks[0].arn
}

resource "aws_eks_cluster" "this" {
  name     = "${var.cluster_name}"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster_version

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    # Disable Legacy bootstrap admin permissions to use managed access entries
    bootstrap_cluster_creator_admin_permissions = false
  }

  encryption_config {
    provider {
      key_arn = local.final_kms_key_arn
    }
    resources = ["secrets"]
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

