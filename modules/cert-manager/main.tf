data "aws_route53_zone" "this" {
  name = var.domain_name
}

resource "aws_iam_policy" "cert_manager_route53" {
  name        = "cert-manager-route53-dns01"
  description = "Allow cert-manager to manage Route53 records for DNS-01 challenges"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:GetChange"]
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${data.aws_route53_zone.this.zone_id}"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZonesByName"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "cert_manager_dns01" {
  name = "cert-manager-dns01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cert_manager_dns01_attach" {
  role       = aws_iam_role.cert_manager_dns01.name
  policy_arn = aws_iam_policy.cert_manager_route53.arn
}

resource "aws_eks_pod_identity_association" "cert_manager" {
  cluster_name    = var.cluster_name
  namespace       = "cert-manager"
  service_account = "cert-manager"
  role_arn        = aws_iam_role.cert_manager_dns01.arn
}
