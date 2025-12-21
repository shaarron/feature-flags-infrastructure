# Feature Flags Infrastructure

A collection of Terraform configurations that provision an entire AWS infrastructure for [**feature-flags-app**]([feature-flags-app](https://github.com/shaarron/feature-flags-app)).

## Table of contents 

- [**Modules**](#modules) 
- [**Terraform**](#terraform)
- [**Workspaces**](#workspaces)
- [**Terraform Backend**](#terraform-backend)
- [**OIDC**](#oidc)
- [**Getting started**](#getting-started)
- [**Getting started using Github Actions workflow**](#getting-started-using-github-actions-workflow)

- [**Prerequisites**](#prerequisites)



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



### **[Terraform](terraform)**

The main Terraform root module. 
It wires together all the above modules for a complete infrastructure stack.

- `main.tf` – Orchestrates all core modules (VPC, EKS, storage, etc.)
- `providers.tf` – AWS, Kubernetes, Helm provider configurations.
- `variables.tf` – Input variable definitions.
- `terraform.tfvars` – Default shared across environemnts variable values.
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

## Getting started using Github Actions workflow

### [Feature Flags Infrastructure](.github/workflows/feature-flags-infrastructure.yaml)

This workflow validates, plans and applys the terraform files based on the user  provision AWS infrastructure resources.

## Getting started

### 1. Configure Workspace 
Create workspace based on the required env(prod, dev, staging):

(e.g., using dev environment) 
```
terraform workspace new dev
```

Swtich to the workspace:
```
terraform workspace select dev
```

### 2. Remote State
If you want to use a **remote state**, you shoud configure it first.

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
2. Enable Backend in Terraform: In t`erraform/providers.tf`, uncomment the backend block so Terraform knows to use S3:
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

once you done configuring remote backend, cd into **terraform/** and run the **[terraform commands](#terraform-commands)** based on your env.

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

