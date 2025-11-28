data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  name_prefix = terraform.workspace
  nlb_hostname = one(
    data.kubernetes_service.ingress_nginx_controller.status[0].load_balancer[0].ingress[*].hostname
  )

  nlb_name = split("-", split(".", local.nlb_hostname)[0])[0]

}

# Read the NLB hostname from the ingress-nginx controller Service
data "kubernetes_service" "ingress_nginx_controller" {
  metadata {
    name      = "ingress-nginx-controller" # controller svc name
    namespace = "ingress-nginx"
  }

  depends_on = [
    time_sleep.wait_3_minutes
  ]

}

module "network" {
  source             = "../modules/network"
  name_prefix        = local.name_prefix
  vpc_cidrs          = var.vpc_cidrs
  availability_zones = var.availability_zones
  single_nat_gateway = var.single_nat_gateway
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.31"
  cluster_name    = "${local.name_prefix}-eks-cluster"
  cluster_version = var.cluster_version
  subnet_ids      = module.network.private_subnet_ids
  vpc_id          = module.network.vpc_id

  cluster_endpoint_private_access          = true
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    main = {
      name         = "${local.name_prefix}"
      desired_size = 2
      max_size     = 4
      min_size     = 1

      instance_types = [var.node_type]
    }
  }
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }
}

module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${local.name_prefix}-ebs-csi"
  attach_ebs_csi_policy = true
  version               = "5.11.0"

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "ebs_csi_storageclass" {
  source                 = "../modules/ebs-csi-storageclass"
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"

  create_namespace = true
  version          = "8.1.3"

  depends_on = [
    module.eks,
    module.eks_blueprints_addons,
  ]
}

resource "kubectl_manifest" "argocd_root_app" {
  yaml_body = file("root-app.yaml")

  depends_on = [
    helm_release.argocd
  ]
}

resource "time_sleep" "wait_3_minutes" {
  depends_on      = [kubectl_manifest.argocd_root_app]
  create_duration = "3m"
}

module "s3_frontend" {
  source                      = "../modules/s3"
  bucket_name                 = "feature-flags-frontend-${local.name_prefix}-sharon"
  versioning                  = var.versioning
  block_public_access         = var.block_public_access
  force_ssl_policy            = var.force_ssl_policy
  server_side_encryption      = var.server_side_encryption
  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_arn

}

module "cloudfront" {

  providers = {
    aws = aws.us_east_1
  }

  source      = "../modules/cloudfront"
  aws_region  = var.aws_region
  name_prefix = local.name_prefix
  aliases     = ["feature-flags${local.name_prefix != "prod" ? ".${local.name_prefix}" : ""}.${var.web_app_domain_name}"]

  origin_domain_name     = local.nlb_hostname
  origin_id              = "nlb-origin"
  origin_protocol_policy = "http-only"
  origin_ssl_protocols   = ["TLSv1.2"]

  ordered_cache_behavior = var.ordered_cache_behavior

  s3_origin                         = module.s3_frontend.s3_bucket
  s3_bucket                         = module.s3_frontend.s3_bucket
  s3_bucket_domain_name             = module.s3_frontend.bucket_regional_domain_name
  default_cache_behavior            = var.default_cache_behavior
  geo_restriction_type              = var.geo_restriction_type
  origin_access_control_origin_type = var.origin_access_control_origin_type
  cert_domain_name                  = var.cert_domain_name

  depends_on = [
    module.cert_manager
  ]
}

module "route53" {
  source = "../modules/route53"

  depends_on = [
    kubectl_manifest.argocd_root_app,
    local.nlb_hostname,
    module.cert_manager
  ]

  aws_region  = var.aws_region
  domain_name = var.web_app_domain_name
  sub_domains = {
    "feature-flags${local.name_prefix != "prod" ? ".${local.name_prefix}" : ""}" = {
      type  = "cloudfront"
      cf_id = module.cloudfront.cloudfront_distribution_id
    }
    "grafana${local.name_prefix != "prod" ? ".${local.name_prefix}" : ""}" = {
      type     = "nlb"
      nlb_name = local.nlb_name
    }
    "kibana${local.name_prefix != "prod" ? ".${local.name_prefix}" : ""}" = {
      type     = "nlb"
      nlb_name = local.nlb_name
    }
  }
}

module "external_secrets_iam" {
  source = "../modules/external-secrets-iam"

  account_id = local.account_id
  region     = var.aws_region

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider
}

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }

  depends_on = [module.eks]
}

resource "kubernetes_service_account" "external_secrets" {
  metadata {
    name      = "external-secrets-sa"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_secrets_iam.role_arn
    }

    labels = {
      "app.kubernetes.io/name" = "external-secrets"
    }
  }

  automount_service_account_token = true
  depends_on                      = [module.external_secrets_iam, kubernetes_namespace.external_secrets]
}
module "cert_manager" {
  source            = "../modules/cert-manager"
  domain_name       = var.web_app_domain_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url

  depends_on = [
    module.eks
  ]
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
  depends_on = [module.eks]
}

resource "kubernetes_service_account" "cert_manager" {
  metadata {
    name      = "cert-manager"
    namespace = kubernetes_namespace.cert_manager.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.cert_manager.role_arn
    }
    labels = {
      "app.kubernetes.io/name" = "cert-manager"
    }
  }
  automount_service_account_token = true
}
