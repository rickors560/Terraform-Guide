provider "aws" {
  region = var.aws_region
}

module "nlb" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "internal-nlb"
  internal    = true
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false

  target_groups = [
    {
      name     = "tcp-app"
      port     = 8080
      protocol = "TCP"
      health_check = {
        protocol            = "HTTP"
        path                = "/health"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 30
      }
    },
    {
      name     = "tls-app"
      port     = 8443
      protocol = "TLS"
      health_check = {
        protocol = "TCP"
      }
    },
  ]

  listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    },
    {
      port               = 443
      protocol           = "TLS"
      certificate_arn    = var.ssl_certificate_arn
      target_group_index = 1
    },
  ]

  team        = var.team
  cost_center = var.cost_center
}
