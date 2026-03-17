provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  availability_zones = var.availability_zones

  public_subnet_newbits  = 8
  private_subnet_newbits = 8
  database_subnet_newbits = 8
  public_subnet_offset   = 0
  private_subnet_offset  = 10
  database_subnet_offset = 20

  enable_nat_gateway           = true
  single_nat_gateway           = false
  enable_flow_logs             = true
  flow_log_retention_days      = 30
  flow_log_traffic_type        = "ALL"
  create_database_subnets      = true
  create_database_subnet_group = true

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository

  additional_tags = {
    Example = "complete"
  }
}
