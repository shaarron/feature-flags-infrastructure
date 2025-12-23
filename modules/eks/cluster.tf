resource "aws_eks_cluster" "this" {
  name     = "${var.cluster_name}"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster_version

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    # Disable bootstrap admin permissions to use Access Entries
    bootstrap_cluster_creator_admin_permissions = false
  }

    dynamic "encryption_config" {
        for_each = var.kms_key_arn != null ? [1] : []
        content {
        provider {
            key_arn = var.kms_key_arn
        }
        resources = ["secrets"]
        }
    }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

