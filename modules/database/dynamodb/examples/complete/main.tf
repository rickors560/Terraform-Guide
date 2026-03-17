provider "aws" {
  region = var.aws_region
}

module "dynamodb" {
  source = "../../"

  project           = var.project
  environment       = var.environment
  table_name_suffix = "orders"

  hash_key       = "PK"
  hash_key_type  = "S"
  range_key      = "SK"
  range_key_type = "S"

  billing_mode                   = "PAY_PER_REQUEST"
  point_in_time_recovery_enabled = true
  ttl_attribute                  = "expires_at"

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  global_secondary_indexes = [
    {
      name            = "GSI1"
      hash_key        = "GSI1PK"
      hash_key_type   = "S"
      range_key       = "GSI1SK"
      range_key_type  = "S"
      projection_type = "ALL"
    }
  ]

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
