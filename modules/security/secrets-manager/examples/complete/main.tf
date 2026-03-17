provider "aws" {
  region = var.aws_region
}

module "db_credentials" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "database/credentials"
  description = "Database credentials for the application"

  kms_key_id              = var.kms_key_id
  recovery_window_in_days = 30

  secret_string = jsonencode({
    username = "admin"
    password = "change-me-after-creation"
    host     = "db.example.com"
    port     = 5432
    dbname   = "myapp"
  })

  team        = var.team
  cost_center = var.cost_center
}

module "api_key" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "api/external-service-key"
  description = "External service API key"

  secret_string = "initial-api-key-value"

  replica_regions = [
    {
      region = "us-west-2"
    },
  ]

  team        = var.team
  cost_center = var.cost_center
}
