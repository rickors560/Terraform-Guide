provider "aws" {
  region = var.aws_region
}

module "eks_cluster" {
  source = "../../"

  project     = var.project
  environment = var.environment

  kubernetes_version      = "1.29"
  subnet_ids              = var.subnet_ids
  endpoint_public_access  = true
  endpoint_private_access = true
  public_access_cidrs     = var.public_access_cidrs

  enabled_cluster_log_types  = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_retention_days = 90

  enable_oidc_provider = true

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
