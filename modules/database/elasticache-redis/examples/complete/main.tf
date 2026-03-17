provider "aws" {
  region = var.aws_region
}

module "redis" {
  source = "../../"

  project     = var.project
  environment = var.environment

  engine_version     = "7.1"
  node_type          = "cache.t3.medium"
  num_cache_clusters = 2

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.auth_token

  automatic_failover_enabled = true
  multi_az_enabled           = true
  snapshot_retention_limit   = 7

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
