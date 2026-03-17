provider "aws" {
  region = var.aws_region
}

module "aurora" {
  source = "../../"

  project     = var.project
  environment = var.environment

  engine_version = "16.3"
  instance_count = 2
  instance_class = "db.r6g.large"

  enable_serverless_v2    = false
  db_name                 = "appdb"
  master_username         = "dbadmin"

  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = var.security_group_ids

  backup_retention_period = 7
  deletion_protection     = true

  iam_database_authentication_enabled = true
  enable_performance_insights         = true

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
