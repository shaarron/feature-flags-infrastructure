# Domain
base_domain = "sharon-k.com"

# ArgoCD
argocd_target_revision = "main"

# Network
availability_zones = 2 # minimum for eks
single_nat_gateway = true

# EKS
cluster_version = "1.32"
node_type       = "r6a.large"
node_group_desired_size = 2
node_group_min_size = 1
node_group_max_size = 4
