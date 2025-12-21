
# Domain
web_app_domain_name = "its-sharon.com"
cert_domain_name    = "*.dev.its-sharon.com"

# Network
availability_zones = 2 # minimum for eks
single_nat_gateway = true

# EKS
cluster_version = "1.32"
node_type       = "r6a.large"
kms_key_arn = "arn:aws:kms:ap-south-1:869432184848:key/400cfeef-6d30-4d63-bf53-eaa387a65456"


