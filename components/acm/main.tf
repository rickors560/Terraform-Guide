###############################################################################
# ACM Component — Certificate with DNS Validation, Route53, SANs
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
  #   key            = "components/acm/terraform.tfstate"
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
      Component   = "acm"
    }
  }
}

# Optional: CloudFront requires certificates in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "acm"
    }
  }
}

# -----------------------------------------------------------------------------
# ACM Certificate (regional — for ALB, API Gateway, etc.)
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# ACM Certificate (us-east-1 — for CloudFront)
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "cloudfront" {
  count    = var.create_cloudfront_certificate ? 1 : 0
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cf-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# DNS Validation Records (in Route53)
# -----------------------------------------------------------------------------

# Regional certificate validation records
resource "aws_route53_record" "validation" {
  for_each = var.route53_zone_id != "" ? {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# CloudFront certificate validation records (same DNS records, different cert)
resource "aws_route53_record" "cf_validation" {
  for_each = var.route53_zone_id != "" && var.create_cloudfront_certificate ? {
    for dvo in aws_acm_certificate.cloudfront[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# -----------------------------------------------------------------------------
# Certificate Validation (wait for DNS validation to complete)
# -----------------------------------------------------------------------------

resource "aws_acm_certificate_validation" "main" {
  count = var.route53_zone_id != "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}

resource "aws_acm_certificate_validation" "cloudfront" {
  count    = var.route53_zone_id != "" && var.create_cloudfront_certificate ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cloudfront[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cf_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}
