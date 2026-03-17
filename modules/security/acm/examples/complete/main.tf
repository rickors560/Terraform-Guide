provider "aws" {
  region = var.aws_region
}

module "acm" {
  source = "../../"

  project     = var.project
  environment = var.environment
  domain_name = var.domain_name
  zone_id     = var.zone_id

  subject_alternative_names = var.subject_alternative_names

  wait_for_validation = true
  validation_timeout  = "45m"
  key_algorithm       = "RSA_2048"

  team        = var.team
  cost_center = var.cost_center
}
