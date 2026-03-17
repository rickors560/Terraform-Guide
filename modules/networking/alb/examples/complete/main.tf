provider "aws" {
  region = var.aws_region
}

module "alb" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "web-alb"
  internal    = false
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids

  security_group_ids = var.security_group_ids

  enable_deletion_protection = false
  idle_timeout               = 60
  drop_invalid_header_fields = true

  enable_https_listener    = true
  ssl_certificate_arn      = var.ssl_certificate_arn
  http_default_action_type = "redirect"

  target_group_port     = 8080
  target_group_protocol = "HTTP"
  target_type           = "ip"

  health_check = {
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  access_logs_enabled = true
  access_logs_bucket  = var.access_logs_bucket
  access_logs_prefix  = "alb-logs"

  team        = var.team
  cost_center = var.cost_center
}
