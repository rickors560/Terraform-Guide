provider "aws" {
  region = var.aws_region
}

module "node_group" {
  source = "../../"

  project     = var.project
  environment = var.environment

  cluster_name           = var.cluster_name
  node_group_name_suffix = "general"
  subnet_ids             = var.subnet_ids

  instance_types = ["t3.large", "t3a.large"]
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  min_size       = 2
  max_size       = 10
  desired_size   = 3
  disk_size      = 50

  labels = {
    role        = "general"
    environment = var.environment
  }

  max_unavailable = 1

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
