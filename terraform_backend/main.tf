terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

module "s3_terrafrom_backend" {
  source                 = "../modules/s3"
  bucket_name            = "feature-flags-terraform-backend-sharon"
  versioning             = true
  block_public_access    = true
  force_ssl_policy       = true
  server_side_encryption = true
}
