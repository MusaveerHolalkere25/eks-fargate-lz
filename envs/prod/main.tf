provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Talks to the cluster created below. Credentials come from `aws eks get-token`,
# so the AWS CLI must be installed where Terraform runs.
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

module "vpc" {
  source = "../../modules/vpc"

  name               = local.name
  vpc_cidr           = var.vpc_cidr
  azs                = local.azs
  single_nat_gateway = var.single_nat_gateway
  cluster_name       = local.name
}

module "eks" {
  source = "../../modules/eks-fargate"

  cluster_name        = local.name
  kubernetes_version  = var.kubernetes_version
  subnet_ids          = module.vpc.private_subnet_ids
  public_access_cidrs = var.api_access_cidrs
  log_retention_days  = var.cluster_log_retention_days

  # Prod keeps every control plane log type for audit and troubleshooting.
  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

module "observability" {
  source = "../../modules/observability"

  cluster_name                   = module.eks.cluster_name
  region                         = var.region
  oidc_provider_arn              = module.eks.oidc_provider_arn
  oidc_provider_url              = module.eks.oidc_provider_url
  private_subnet_ids             = module.vpc.private_subnet_ids
  fargate_pod_execution_role_arn = module.eks.fargate_pod_execution_role_arn
  log_retention_days             = var.observability_log_retention_days
  grafana_admin_user_ids         = var.grafana_admin_user_ids
  grafana_admin_group_ids        = var.grafana_admin_group_ids

  # Pods can only schedule once Fargate profiles and CoreDNS are in place.
  depends_on = [module.eks]
}
