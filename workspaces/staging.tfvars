# Domain
web_app_domain_name = "its-sharon.com"
cert_domain_name    = "*.staging.its-sharon.com"

# Network
availability_zones = 3
single_nat_gateway = false

# EKS
cluster_version = "1.32"
node_type       = "r6a.large"
node_group_desired_size = 2
node_group_min_size = 1
node_group_max_size = 4
kms_key_arn = "<staging kms key arn>"
