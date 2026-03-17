###############################################################################
# Route53 Component — Hosted Zone with Various Record Types & Health Check
###############################################################################

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/route53/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "route53"
    }
  }
}

# Route53 health checks must be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "route53"
    }
  }
}

# -----------------------------------------------------------------------------
# Hosted Zone
# -----------------------------------------------------------------------------

resource "aws_route53_zone" "main" {
  name          = var.domain_name
  comment       = "Hosted zone for ${var.project_name} (${var.environment})"
  force_destroy = var.environment != "prod"

  tags = {
    Name = "${var.project_name}-${var.environment}-zone"
  }
}

# -----------------------------------------------------------------------------
# A Record (standard)
# -----------------------------------------------------------------------------

resource "aws_route53_record" "a_records" {
  for_each = var.a_records

  zone_id = aws_route53_zone.main.zone_id
  name    = each.key
  type    = "A"
  ttl     = each.value.ttl
  records = each.value.records
}

# -----------------------------------------------------------------------------
# A Record (alias — e.g., ALB, CloudFront, S3)
# -----------------------------------------------------------------------------

resource "aws_route53_record" "alias_records" {
  for_each = var.alias_records

  zone_id = aws_route53_zone.main.zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = each.value.dns_name
    zone_id                = each.value.zone_id
    evaluate_target_health = each.value.evaluate_target_health
  }
}

# -----------------------------------------------------------------------------
# CNAME Records
# -----------------------------------------------------------------------------

resource "aws_route53_record" "cname_records" {
  for_each = var.cname_records

  zone_id = aws_route53_zone.main.zone_id
  name    = each.key
  type    = "CNAME"
  ttl     = each.value.ttl
  records = [each.value.value]
}

# -----------------------------------------------------------------------------
# MX Records
# -----------------------------------------------------------------------------

resource "aws_route53_record" "mx" {
  count = length(var.mx_records) > 0 ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = var.mx_ttl
  records = var.mx_records
}

# -----------------------------------------------------------------------------
# TXT Records
# -----------------------------------------------------------------------------

resource "aws_route53_record" "txt_records" {
  for_each = var.txt_records

  zone_id = aws_route53_zone.main.zone_id
  name    = each.key
  type    = "TXT"
  ttl     = each.value.ttl
  records = each.value.values
}

# -----------------------------------------------------------------------------
# CAA Record (Certificate Authority Authorization)
# -----------------------------------------------------------------------------

resource "aws_route53_record" "caa" {
  count = length(var.caa_records) > 0 ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "CAA"
  ttl     = 3600
  records = var.caa_records
}

# -----------------------------------------------------------------------------
# Health Check
# -----------------------------------------------------------------------------

resource "aws_route53_health_check" "main" {
  count = var.health_check_fqdn != "" ? 1 : 0

  fqdn              = var.health_check_fqdn
  port               = var.health_check_port
  type               = var.health_check_type
  resource_path      = var.health_check_type == "HTTPS" || var.health_check_type == "HTTP" ? var.health_check_resource_path : null
  failure_threshold  = var.health_check_failure_threshold
  request_interval   = var.health_check_request_interval
  measure_latency    = true
  enable_sni         = var.health_check_type == "HTTPS"

  regions = var.health_check_regions

  tags = {
    Name = "${var.project_name}-${var.environment}-health-check"
  }

  provider = aws.us_east_1
}

# CloudWatch alarm for health check
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count    = var.health_check_fqdn != "" ? 1 : 0
  provider = aws.us_east_1

  alarm_name          = "${var.project_name}-${var.environment}-route53-health-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Route53 health check failed for ${var.health_check_fqdn}"
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.main[0].id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-health-check-alarm"
  }
}

# -----------------------------------------------------------------------------
# DNSSEC (optional)
# -----------------------------------------------------------------------------

resource "aws_route53_hosted_zone_dnssec" "main" {
  count = var.enable_dnssec ? 1 : 0

  hosted_zone_id = aws_route53_zone.main.zone_id

  depends_on = [aws_route53_zone.main]
}
