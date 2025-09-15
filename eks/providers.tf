terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "feature-flags-terraform-75c725529b57408e" 
    key            = "terraform_modules/terraform.tfstate"
    region         = "ap-south-1"
    use_lockfile = true
    }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region

  default_tags {
    tags = var.common_tags
  }
}
