locals {
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
    namespace = "default"
  }

  provider = kubernetes.eks
  depends_on = [
    module.eks,                # ensures cluster exists
    helm_release.ingress_nginx # ensures service exists
  ]

}

module "network" {
  source             = "../modules/network"
  name_prefix        = local.name_prefix
  vpc_cidrs          = var.vpc_cidrs
  availability_zones = var.availability_zones
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

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]
  depends_on = [module.eks]

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

module "s3_frontend" {
  source                      = "../modules/s3"
  bucket_name                 = "feature-flags-frontend-${local.name_prefix}-sharon"
  versioning                  = var.versioning
  block_public_access         = var.block_public_access
  force_ssl_policy            = var.force_ssl_policy
  server_side_encryption      = var.server_side_encryption
  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_id
}


module "cloudfront" {
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
  default_cache_behavior            = var.default_cache_behavior
  geo_restriction_type              = var.geo_restriction_type
  origin_access_control_origin_type = var.origin_access_control_origin_type
  cert_domain_name                  = var.cert_domain_name
}

module "route53" {
  source = "../modules/route53"

  depends_on = [
    module.eks,
    helm_release.ingress_nginx
  ]

  providers = {
    kubernetes = kubernetes.eks
  }

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

## argocd 
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
    helm_release.ingress_nginx
  ]
}

# # Git repo secret for ArgoCD to access resources repository (public)
# resource "kubectl_manifest" "argocd_repo_public" {
#   yaml_body = <<YAML
# apiVersion: v1
# kind: Secret
# metadata:
#   name: repo-feature-flags-public
#   namespace: argocd
#   labels:
#     argocd.argoproj.io/secret-type: repository
# stringData:
#   type: git
#   url: https://github.com/shaarron/feature-flags-resources.git
# YAML

#   depends_on = [helm_release.argocd]
# }
