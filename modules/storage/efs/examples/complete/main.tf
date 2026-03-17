provider "aws" {
  region = var.aws_region
}

module "efs" {
  source = "../../"

  project     = var.project
  environment = var.environment

  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
  encrypted        = true

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  lifecycle_policy_transition_to_ia      = "AFTER_30_DAYS"
  lifecycle_policy_transition_to_primary = "AFTER_1_ACCESS"

  enable_backup = true

  access_points = [
    {
      name = "app"
      posix_user = {
        uid = 1000
        gid = 1000
      }
      root_directory = {
        path = "/app"
        creation_info = {
          owner_uid   = 1000
          owner_gid   = 1000
          permissions = "755"
        }
      }
    }
  ]

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
