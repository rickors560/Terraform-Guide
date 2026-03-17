provider "aws" {
  region = var.aws_region
}

module "ecr" {
  source = "../../"

  project                = var.project
  environment            = var.environment
  repository_name_suffix = "api"

  image_tag_mutability       = "IMMUTABLE"
  scan_on_push               = true
  encryption_type            = "AES256"
  max_tagged_image_count     = 30
  untagged_image_expiry_days = 7

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
