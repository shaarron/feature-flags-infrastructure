# feature-flags-infrastructure

A collection of Terraform configurations that provision AWS infrastructure for feature-flags app.

## Repository layout

- [cloudfront_s3](cloudfront_s3) — CloudFront distribution and creation of S3 bucket for static assets(UI).
- [eks](eks/) — EKS cluster, network and storage configuration. 
- [terraform_backend](terraform_backend) — Remote state backend configuration (S3).


## Prerequisites

- Terraform (>= 1.0 recommended)
- AWS CLI configured with appropriate credentials and region
- create terraform.tfvars for each module with the required variables


## Getting started

1. Configure the remote state backend first:
   - cd into [terraform_backend](terraform_backend/) and run:
     - terraform init
     - terraform plan
     - terraform apply
2. For each environment component:
   - Example for EKS:
     - cd [eks](eks/)
     - terraform init
     - terraform plan -var-file="terraform.tfvars"
     - terraform apply -var-file="terraform.tfvars"
   - Example for CloudFront + S3:
     - cd [cloudfront_s3](cloudfront_s3/)
     - terraform init
     - terraform apply -var-file="terraform.tfvars"

