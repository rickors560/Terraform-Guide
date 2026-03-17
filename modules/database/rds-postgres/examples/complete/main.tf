provider "aws" {
  region = var.aws_region
}

module "rds_postgres" {
  source = "../../"

  project     = var.project
  environment = var.environment

  engine_version = "16.3"
  instance_class = "db.t3.medium"

  allocated_storage     = 50
  max_allocated_storage = 200
  storage_type          = "gp3"

  db_name  = "appdb"
  username = "dbadmin"

  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = var.security_group_ids

  multi_az               = true
  backup_retention_period = 7
  deletion_protection    = true

  enable_performance_insights = true
  enable_enhanced_monitoring  = true
  monitoring_interval         = 60

  parameters = [
    {
      name  = "log_min_duration_statement"
      value = "1000"
    },
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    }
  ]

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
