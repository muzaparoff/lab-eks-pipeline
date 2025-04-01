terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  # Enable CodeCommit repository creation
  ignore_tags {
    key_prefixes = ["aws:"]
  }
}

provider "aws" {
  alias  = "codecommit"
  region = var.aws_region

  assume_role {
    role_arn = aws_iam_role.codecommit_role.arn
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }

  # Add these for aws-auth ConfigMap
  ignore_annotations = [
    "^kubernetes\\.io/",
    "^eks\\.amazonaws\\.com/",
  ]
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "eks" {
  source = "./modules/eks"
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  cluster_version = var.eks_version
  cluster_name = var.cluster_name
}

module "rds" {
  source = "./modules/rds"
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  db_username = var.db_username
  db_password = var.db_password
  db_engine   = var.db_engine
  db_name     = var.db_name
}

module "route53_acm" {
  source = "./modules/route53_acm"
  domain_name = var.domain_name
  cert_domain = var.cert_domain
  vpc_id = module.vpc.vpc_id
  cluster_endpoint = module.eks.cluster_endpoint

  depends_on = [
    module.vpc,
    module.eks
  ]
}

module "windows_instance" {
  source = "./modules/windows_instance"
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}

# Add AWS Load Balancer Controller Helm release
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  depends_on = [module.eks]
}

# Add ArgoCD installation
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  depends_on = [module.eks]
}

resource "local_file" "helm_values" {
  content = templatefile("${path.module}/templates/values.yaml.tpl", {
    rds_endpoint        = module.rds.endpoint
    db_name            = var.db_name
    app_version        = var.app_version
    domain_name        = var.cert_domain
    acm_certificate_arn = module.route53_acm.certificate_arn
  })
  filename = "${path.module}/../helm/lab-app/values.yaml"
}