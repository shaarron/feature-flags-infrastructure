
project_name = "feature-flags"
aws_region = "ap-south-1"

# Domain
web_app_domain_name = "its-sharon.com"
cert_domain_name = "*.dev.its-sharon.com"

# Network
vpc_cidrs          = "10.0.0.0/16"

# EKS
cluster_version    = "1.31"
node_type          = "r6a.large"

#?
ha                 = 2

# S3
s3_static_bucket_name = "ff-static-ui-dev"
s3_force_destroy     = true

## for argocd - while the repository is private
github_private_key = <<EOKEY

EOKEY
