
# Domain
web_app_domain_name = "its-sharon.com"
cert_domain_name    = "*.its-sharon.com"

# Network
availability_zones = 3
single_nat_gateway = false

# EKS
cluster_version = "1.32"
node_type       = "t3.large"
kms_key_arn = "<prod kms key arn>"
