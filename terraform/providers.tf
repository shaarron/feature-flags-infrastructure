terraform {
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    kubectl    = { source = "gavinbunney/kubectl", version = ">= 1.14.0" }
    helm       = { source = "hashicorp/helm", version = ">= 2.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.0" }
  }

  # backend "s3" {}
}

locals {
  cluster_host  = module.eks.cluster_endpoint
  cluster_ca    = base64decode(module.eks.cluster_certificate_authority_data)
  cluster_token = data.aws_eks_cluster_auth.this.token
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

# Separate provider for us-east-1 for CloudFront and ACM
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = var.common_tags
  }
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_host
    cluster_ca_certificate = local.cluster_ca
    token                  = local.cluster_token
  }
}

provider "kubernetes" {
  host                   = local.cluster_host
  cluster_ca_certificate = local.cluster_ca
  token                  = local.cluster_token
}

provider "kubectl" {
  host                   = local.cluster_host
  cluster_ca_certificate = local.cluster_ca
  token                  = local.cluster_token
}