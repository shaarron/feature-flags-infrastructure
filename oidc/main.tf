# GitHub OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "gha_oidc_role" {
  name = "gha-oidc-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          "token.actions.githubusercontent.com:sub" = ["repo:shaarron/feature-flags-app:ref:refs/heads/main", "repo:shaarron/feature-flags-infrastructure:ref:refs/heads/main"]
        }
      }
    }]
  })
}

resource "aws_iam_policy" "gha_custom_policy" {
  name        = "gha-deploy-policy"
  description = "Scoped permissions for GitHub Actions to deploy the infrastructure and push images to ECR. implementing least privilege principle."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InfrastructureProvisioning"
        Effect = "Allow"
        Action = [
          # S3
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutBucketVersioning",
          "s3:GetBucketVersioning",
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutEncryptionConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:GetLifecycleConfiguration",

          # EC2 (VPC, Subnets, NAT GW, IGW, Security Groups)
          "ec2:*",

          # EKS (Cluster & Addons)
          "eks:*",

          # AutoScaling (Node Groups)
          "autoscaling:*",

          # IAM (Creating Roles for EKS, IRSA, CertManager, etc.)
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:UpdateRole",
          "iam:TagRole",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfiles",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:ListPolicyVersions",
          "iam:CreateOpenIDConnectProvider", 
          "iam:GetOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",

          # Route53 (DNS Records)
          "route53:*",

          # CloudFront (Distribution & OAC)
          "cloudfront:*",

          # ACM (Certificate Validation)
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "acm:GetCertificate",

          # KMS (EKS Secret Encryption)
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:ScheduleKeyDeletion",
          "kms:GetKeyPolicy",
          "kms:PutKeyPolicy",
          "kms:TagResource",

          # Elastic Load Balancing (For Ingress/Service interactions)
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AppContainerRegistry"
        Effect = "Allow"
        Action = [
          # ECR: Login & Push (For the App Repo)
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:DescribeRepositories" 
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gha_custom_attach" {
  role       = aws_iam_role.gha_oidc_role.name
  policy_arn = aws_iam_policy.gha_custom_policy.arn
}