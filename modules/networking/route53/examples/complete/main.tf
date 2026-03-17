provider "aws" {
  region = var.aws_region
}

module "route53" {
  source = "../../"

  project     = var.project
  environment = var.environment
  zone_name   = var.zone_name

  create_zone   = true
  private_zone  = false
  force_destroy = true

  records = {
    "${var.zone_name}" = {
      type = "A"
      alias = {
        name    = var.alb_dns_name
        zone_id = var.alb_zone_id
      }
    }
    "www.${var.zone_name}" = {
      type    = "CNAME"
      ttl     = 300
      records = [var.zone_name]
    }
    "${var.zone_name}-mx" = {
      type    = "MX"
      ttl     = 3600
      records = ["10 mail.${var.zone_name}", "20 mail2.${var.zone_name}"]
    }
    "${var.zone_name}-txt" = {
      type    = "TXT"
      ttl     = 300
      records = ["v=spf1 include:_spf.google.com ~all"]
    }
  }

  health_checks = {
    "primary" = {
      fqdn          = var.zone_name
      type          = "HTTPS"
      resource_path = "/health"
      port          = 443
    }
  }

  team        = var.team
  cost_center = var.cost_center
}
