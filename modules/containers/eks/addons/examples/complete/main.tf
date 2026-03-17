provider "aws" {
  region = var.aws_region
}

module "eks_addons" {
  source = "../../"

  project      = var.project
  environment  = var.environment
  cluster_name = var.cluster_name

  addons = {
    vpc-cni = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    coredns = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
