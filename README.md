# Feature Flags Infrastructure

A collection of Terraform configurations that provision an entire AWS infrastructure for [**feature-flags-app**]([feature-flags-app](https://github.com/shaarron/feature-flags-app)).

## Table of contents 

- [**Modules**](#modules) 
- [**Root Module**](#root-module)
- [**Workspaces**](#workspaces)
- [**Terraform Backend**](#terraform-backend)
- [**OIDC**](#oidc)
- [**Running manually**](#running-manually)
- [**Running using Github Actions workflow**](#running-using-github-actions-workflow)

- [**Prerequisites**](#prerequisites)
- [**Cost Estimation**](#cost-estimation)



### [Modules](modules)

All the modules are **custom-developed** for this project.

These modules are composed by the main application stack in `terraform/`.

| Module                   | Purpose                                                                                                                                      |
|--------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| `cloudfront/`            | Configures a CloudFront distribution with OAC/OAI, custom cache policies, and Route 53 aliases.                                             |
| `ebs-csi-storageclass/`  | Creates EBS CSI storage classes (e.g., gp3), sets one as default.                                                                            |
| `network/`               | Creates the VPC, subnets, route tables, IGWs, NAT gateways.                                                                                   |
| `route53/`               | Creates DNS records for S3/CloudFront/NLB.                                                                                                   |
| `s3/`                    | Creates S3 buckets with encryption and access control.                                                                                       |
| `cert-manager/`          | Configures IAM roles (IRSA) for cert-manager to manage Route53 DNS records for DNS-01 challenges.                                            |
| `external-secrets-iam/`  | Configures IAM permissions for External Secrets Operator to read from AWS Secrets Manager.                                                   |
| `eks/`                   | Creates an EKS cluster with managed node groups, IAM roles for service accounts (IRSA), and necessary security groups.                       |



### **[Root Module](terraform)**

The main Terraform root module. 
It wires together all the above modules for a complete infrastructure stack.

- `main.tf` – Orchestrates all core modules (VPC, EKS, storage, etc.)
- `providers.tf` – AWS, Kubernetes, Helm provider configurations.
- `variables.tf` – Input variable definitions.
- `terraform.tfvars` – Default shared across environments variable values.
- `outputs.tf` – Useful outputs like DNS names, ARNs, endpoints.
  

###  **[Workspaces](workspaces)**

Environment-specific variable overrides to support **multi-env deployments**.

 `dev.tfvars`, `staging.tfvars`, `prod.tfvars`


### **[OIDC](oidc)**

A standalone configuration located in `oidc/`. 
- **Purpose:** Sets up the IAM OIDC provider to allow GitHub Actions to assume AWS roles.
- **Usage:** This must be applied separately **before** running the main pipeline if you intend to use GitHub Actions.

### **[Terraform Backend](terraform_backend)**

Provisioning the remote S3 backend for Terraform state.
- Creates encrypted S3 bucket with versioning.
- Applies secure public access blocking and bucket policies.
  

## Prerequisites

- Terraform (>= 1.0 recommended)
- AWS CLI configured with appropriate credentials and region
- **Route 53 Hosted Zone:** A public hosted zone for your domain (e.g., `your-domain.com`) must already exist in the AWS account.
- **ACM Certificate:** A valid SSL/TLS certificate for your domain (or wildcard, e.g., `*.your-domain.com`) must exist in the **us-east-1** (N. Virginia) region.
  > **Note:** CloudFront requires certificates to be in `us-east-1`, even if your main infrastructure is in other region (e.g, ap-south-1).
- Prepare terraform.tfvars for each module with the required variables.


## Required AWS Permissions & IAM Roles

To successfully apply this Terraform configuration, the IAM user or role running this Terraform must have administrator-level permissions(Create, Read, Write and Delete) over the following services:

- **EKS**

- **IAM**

- **EC2** 
  
- **EBS**

- **S3**

- **CloudFront**

- **Route 53**

- **ACM**

- **CloudWatch Logs**

## Cost Estimation

Estimated monthly infrastructure costs for a **high availability and resilient production setup**, based on `ap-south-1` (Mumbai) pricing as of Dec 2025. Does not include variable data transfer or request fees.

| Resource | Quantity | Unit Price (Monthly) | Total (Monthly) | Notes |
|----------|----------|---------------------|-----------------|-------|
| **EKS Cluster** | 1 | $73.00 | **$73.00** | $0.10/hour flat fee |
| **EC2 Nodes (`r6a.large`)** | 3 | ~$52.20 | **$156.60** | On-demand pricing ($0.0715/hr) |
| **NAT Gateways** | 3 | $32.85 | **$98.55** | One per AZ for high availability ($0.045/hr) |
| **Network Load Balancer** | 1 | $16.43 | **$16.43** | Base hourly rate ($0.0225/hr) |
| **EBS Storage (gp3)** | 60 GB | $0.091/GB | **$5.46** | 20GB root volume per node |
| **VPC Service** | 1 | Free | **$0.00** | Logically isolated virtual network |
| **Public IPv4 Addresses** | 6 | $3.65 | **$21.90** | $0.005/hr (3 NAT GWs + 3 NLB IPs) |
| **Route 53 Hosted Zone** | 1 | $0.50 | **$0.50** | Per hosted zone |
| **Total** | | | **~$372.44** | *Excludes data transfer & NLCU charges* |

> **Note:** Costs can vary based on region, instance types, and usage (e.g., NAT Gateway data processing at $0.045/GB, S3 requests, and CloudFront transfer out).

### Cost Estimation - Development Setup (Optimized)

*Mumbai (ap-south-1) | Single-AZ | Spot + Scale-to-Zero*

| Resource | Quantity | Unit Price (Monthly) | Total (Monthly) | Reduction Tweak |
|----------|----------|---------------------|-----------------|-----------------|
| **EKS Control Plane** | 1 | $73.00 | **$73.00** | - |
| **EC2 Nodes (`r6a.large`)** | 2 | ~$21.00 | **$42.00** | **Spot Instances** (~60% off) |
| **NAT Gateway** | 1 | $32.85 | **$11.00** | **Scale to 0** (Off-hours) |
| **Storage (gp3)** | 40 GB | $0.09/GB | **$3.60** | Minimal Root Volumes |
| **Public IPv4s** | 2 | $3.65 | **$2.40** | **Scale to 0** (Off-hours) |
| **Total** | | | **~$132.00** | **~65% Total Savings** |

## Getting started using Github Actions workflow

#### [Feature Flags Infrastructure workflow](.github/workflows/feature-flags-infrastructure.yaml)

This workflow validates, plans and applies the terraform files based on the workspace selected and tfvars file.

## Running manually

### 1. Configure Workspace 
Create workspace based on the required env(prod, dev, staging):

(e.g., using dev environment) 
```
terraform workspace new dev
```

Switch to the workspace:
```
terraform workspace select dev
```

### 2. Remote State
If you want to use a **remote state**, you should configure it first.

you can create a new bucket or use your own

#### To create a remote backend


```
cd terraform_backend/
terraform init
terraform apply
```

#### To configure backend

1. Update Configuration File: Edit `terraform/backend.hcl` with your bucket name and region:

   ```
   bucket = "your-backend-bucket-name"
   region = "ap-south-1"
   ```
2. Enable Backend in Terraform: In `terraform/providers.tf`, uncomment the backend block so Terraform knows to use S3:
   ```
   # backend "s3" {}
   ```

3. Initialize with Backend Config
When initializing Terraform, you must now tell it to use your `backend.hcl` file and specify a key (path) for the state file.

   ```
   cd terraform/

   terraform init -backend-config="backend.hcl" -backend-config="key=workspaces/dev/terraform.tfstate"
   ```
#### 3. Deploy the whole setup

once you are done configuring remote backend, cd into **terraform/** and run the **[terraform commands](#terraform-commands)** based on your env.

```
cd terraform/
```

### Terraform commands
for each step use the following commands:

(*example using dev environemnt)
```
terraform init
```

```
terraform plan -var-file="../workspaces/dev.tfvars" 
```
```
terraform apply -var-file="../workspaces/dev.tfvars"
```



   


## Troubleshooting

Below are some common Terraform issues you might encounter during deployment and their typical resolutions.

### Error: `Invalid value for input variable`

**Cause:**  
The `terraform.tfvars` or environment-specific `*.tfvars` file is missing required variables, or a variable is passed with the wrong type (e.g., string instead of list).

**Fix:**  
- Double check the variables required in `variables.tf`.
- Validate your inputs using:

  ```bash
  terraform validate
  terraform plan -var-file="workspaces/dev.tfvars"
   ```


### Error: 403 AccessDenied (across AWS resources)

**Cause:**  
Your IAM user, role, or federated identity (e.g., GitHub OIDC) lacks the necessary permissions to access an AWS resource — such as S3, Route 53, CloudFront, IAM, or EKS.

**Fix:**  
- Confirm your current identity:
  ```bash
  aws sts get-caller-identity
   ```

- Check whether the identity has the appropriate actions for the resource type, e.g.:

   * S3 → s3:GetObject, s3:PutObject, s3:ListBucket, s3:DeleteObject

   * Route53 → route53:ChangeResourceRecordSets, route53:ListHostedZones

   * IAM/OIDC → iam:PassRole, iam:GetRole, iam:CreateOpenIDConnectProvider

