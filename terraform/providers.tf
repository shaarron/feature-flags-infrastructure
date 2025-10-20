terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
# backend configutation optional
  # backend "s3" {
  #   bucket         = "<YOUR_BUCKET_NAME>" 
  #   key            = "terraform_modules/terraform.tfstate"
  #   region         = "<YOUR_AWS_REGION>"
  #   use_lockfile = true
  #   }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}
