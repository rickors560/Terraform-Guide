provider "aws" {
  region = var.aws_region
}

module "kms" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "app-encryption"
  description = "Application-level encryption key"

  enable_key_rotation     = true
  rotation_period_in_days = 365
  deletion_window_in_days = 30
  multi_region            = false

  key_administrators = var.key_administrator_arns
  key_users          = var.key_user_arns

  team        = var.team
  cost_center = var.cost_center
}
