# -----------------------------------------------------------------------------
# WAF v2 Component - Web ACL, Rate Limiting, IP Blocking, Managed Rules
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/waf/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "waf"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# IP Sets
# -----------------------------------------------------------------------------

resource "aws_wafv2_ip_set" "blocked_ips" {
  name               = "${local.name_prefix}-blocked-ips"
  description        = "IP addresses blocked from accessing the application"
  scope              = var.waf_scope
  ip_address_version = "IPV4"
  addresses          = var.blocked_ip_addresses

  tags = {
    Name = "${local.name_prefix}-blocked-ips"
  }
}

resource "aws_wafv2_ip_set" "allowed_ips" {
  name               = "${local.name_prefix}-allowed-ips"
  description        = "IP addresses explicitly allowed (whitelisted)"
  scope              = var.waf_scope
  ip_address_version = "IPV4"
  addresses          = var.allowed_ip_addresses

  tags = {
    Name = "${local.name_prefix}-allowed-ips"
  }
}

# -----------------------------------------------------------------------------
# Web ACL
# -----------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "main" {
  name        = "${local.name_prefix}-web-acl"
  description = "WAF Web ACL for ${local.name_prefix}"
  scope       = var.waf_scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${replace(local.name_prefix, "-", "")}WebAcl"
    sampled_requests_enabled   = true
  }

  # -------------------------------------------------------------------------
  # Rule 1: Block listed IPs (highest priority)
  # -------------------------------------------------------------------------
  rule {
    name     = "block-listed-ips"
    priority = 0

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blocked_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(local.name_prefix, "-", "")}BlockedIPs"
      sampled_requests_enabled   = true
    }
  }

  # -------------------------------------------------------------------------
  # Rule 2: Allow listed IPs (bypass other rules)
  # -------------------------------------------------------------------------
  rule {
    name     = "allow-listed-ips"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(local.name_prefix, "-", "")}AllowedIPs"
      sampled_requests_enabled   = true
    }
  }

  # -------------------------------------------------------------------------
  # Rule 3: Rate limiting
  # -------------------------------------------------------------------------
  rule {
    name     = "rate-limit"
    priority = 2

    action {
      block {
        custom_response {
          response_code = 429
          custom_response_body_key = "rate-limit-response"
        }
      }
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(local.name_prefix, "-", "")}RateLimit"
      sampled_requests_enabled   = true
    }
  }

  # -------------------------------------------------------------------------
  # Rule 4: AWS Managed - Common Rule Set
  # -------------------------------------------------------------------------
  rule {
    name     = "aws-managed-common-rules"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "NoUserAgent_HEADER"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(local.name_prefix, "-", "")}CommonRules"
      sampled_requests_enabled   = true
    }
  }

  # -------------------------------------------------------------------------
  # Rule 5: AWS Managed - Known Bad Inputs
  # -------------------------------------------------------------------------
  rule {
    name     = "aws-managed-known-bad-inputs"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(local.name_prefix, "-", "")}KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  # -------------------------------------------------------------------------
  # Rule 6: AWS Managed - SQL Injection
  # -------------------------------------------------------------------------
  rule {
    name     = "aws-managed-sqli"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(local.name_prefix, "-", "")}SQLi"
      sampled_requests_enabled   = true
    }
  }

  # -------------------------------------------------------------------------
  # Rule 7: AWS Managed - Amazon IP Reputation List
  # -------------------------------------------------------------------------
  rule {
    name     = "aws-managed-ip-reputation"
    priority = 6

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(local.name_prefix, "-", "")}IPReputation"
      sampled_requests_enabled   = true
    }
  }

  # -------------------------------------------------------------------------
  # Rule 8: Geo-restriction (block specific countries)
  # -------------------------------------------------------------------------
  dynamic "rule" {
    for_each = length(var.blocked_country_codes) > 0 ? [1] : []

    content {
      name     = "geo-restriction"
      priority = 7

      action {
        block {}
      }

      statement {
        geo_match_statement {
          country_codes = var.blocked_country_codes
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${replace(local.name_prefix, "-", "")}GeoBlock"
        sampled_requests_enabled   = true
      }
    }
  }

  custom_response_body {
    key          = "rate-limit-response"
    content      = "{\"error\": \"Too many requests. Please slow down.\"}"
    content_type = "APPLICATION_JSON"
  }

  tags = {
    Name = "${local.name_prefix}-web-acl"
  }
}

# -----------------------------------------------------------------------------
# WAF Logging Configuration
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "aws-waf-logs-${local.name_prefix}"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn

  logging_filter {
    default_behavior = "KEEP"

    filter {
      behavior    = "KEEP"
      requirement = "MEETS_ANY"

      condition {
        action_condition {
          action = "BLOCK"
        }
      }

      condition {
        action_condition {
          action = "COUNT"
        }
      }
    }
  }

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}

# -----------------------------------------------------------------------------
# WAF Association with ALB (optional)
# -----------------------------------------------------------------------------

resource "aws_wafv2_web_acl_association" "alb" {
  count = var.alb_arn != "" ? 1 : 0

  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# -----------------------------------------------------------------------------
# CloudWatch Metrics Alarms for WAF
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "blocked_requests" {
  alarm_name          = "${local.name_prefix}-waf-blocked-requests-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300
  statistic           = "Sum"
  threshold           = var.blocked_requests_threshold
  alarm_description   = "WAF blocked requests exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    WebACL = aws_wafv2_web_acl.main.name
    Region = var.region
    Rule   = "ALL"
  }

  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = {
    Name = "${local.name_prefix}-waf-blocked-requests"
  }
}

resource "aws_cloudwatch_metric_alarm" "rate_limited_requests" {
  alarm_name          = "${local.name_prefix}-waf-rate-limited-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300
  statistic           = "Sum"
  threshold           = var.rate_limit_alarm_threshold
  alarm_description   = "WAF rate limiting triggered excessively"
  treat_missing_data  = "notBreaching"

  dimensions = {
    WebACL = aws_wafv2_web_acl.main.name
    Region = var.region
    Rule   = "rate-limit"
  }

  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = {
    Name = "${local.name_prefix}-waf-rate-limited"
  }
}
