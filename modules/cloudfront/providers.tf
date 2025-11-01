terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket       = "<BACKEND_BUCKET_NAME>"
  #   key          = "s3-cf/terraform.tfstate"
  #   region       = "ap-south-1"
  #   use_lockfile = true
  # }
}

provider "aws" {
  region = var.aws_region
}

# Extra provider for us-east-1 (needed for ACM + CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}