# feature-flags-infrastructure

A collection of Terraform configurations that provision AWS infrastructure for feature-flags app.

## Repository layout

- [cloudfront_s3](cloudfront_s3) — CloudFront distribution and creation of S3 bucket for static assets(UI).
- [eks](eks/) — EKS cluster, network and storage configuration. 
- [terraform_backend](terraform_backend) — Remote state backend configuration (S3).


## Prerequisites

- Terraform (>= 1.0 recommended)
- AWS CLI configured with appropriate credentials and region
- Prepare terraform.tfvars for each module with the required variables.



## Getting started

for each step use the following commands:
     - terraform init
     - terraform plan
     - terraform apply
1. Configure the remote state backend first:
   - cd into [terraform_backend](terraform_backend/) and run terrafrom commands.
2. Create EKS & Network & Storage
   - cd [eks](eks/) and run terrafrom commands.
   - *once eks cluster created, apply the k8s resources. 
3. Create CloudFront + S3:
     - Run this only after applying k8s resources on EKS - you'll need to use the NLB URL. 
     - cd [cloudfront_s3](cloudfront_s3/) and run terrafrom commands.

