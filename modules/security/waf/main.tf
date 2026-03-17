###############################################################################
# IP Set (Block List)
###############################################################################

resource "aws_wafv2_ip_set" "block_list" {
  count = var.enable_ip_block_rule ? 1 : 0

  name               = "${local.name_prefix}-${var.name}-block-list"
  description        = "IP addresses blocked by ${local.name_prefix} WAF"
  scope              = var.scope
  ip_address_version = var.ip_address_version
  addresses          = var.blocked_ip_addresses

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.name}-block-list"
  })
}

###############################################################################
# WAF v2 Web ACL
###############################################################################

resource "aws_wafv2_web_acl" "this" {
  name        = "${local.name_prefix}-${var.name}"
  description = var.description
  scope       = var.scope

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }
    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
    metric_name                = "${replace(local.name_prefix, "-", "")}${replace(var.name, "-", "")}WebACL"
    sampled_requests_enabled   = var.sampled_requests_enabled
  }

  # IP Block Rule
  dynamic "rule" {
    for_each = var.enable_ip_block_rule ? [1] : []
    content {
      name     = "${local.name_prefix}-ip-block"
      priority = var.ip_block_priority

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.block_list[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        metric_name                = "${replace(local.name_prefix, "-", "")}IPBlockRule"
        sampled_requests_enabled   = var.sampled_requests_enabled
      }
    }
  }

  # Rate Limit Rule
  dynamic "rule" {
    for_each = var.enable_rate_limit_rule ? [1] : []
    content {
      name     = "${local.name_prefix}-rate-limit"
      priority = var.rate_limit_priority

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.rate_limit
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        metric_name                = "${replace(local.name_prefix, "-", "")}RateLimitRule"
        sampled_requests_enabled   = var.sampled_requests_enabled
      }
    }
  }

  # AWS Managed Rule Groups
  dynamic "rule" {
    for_each = var.managed_rule_groups
    content {
      name     = "${local.name_prefix}-${lower(rule.value.name)}"
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name

          dynamic "rule_action_override" {
            for_each = rule.value.excluded_rules
            content {
              name = rule_action_override.value
              action_to_use {
                count {}
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
        metric_name                = "${replace(local.name_prefix, "-", "")}${replace(rule.value.name, "-", "")}"
        sampled_requests_enabled   = var.sampled_requests_enabled
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.name}"
  })
}

###############################################################################
# Web ACL Association (REGIONAL scope only)
###############################################################################

resource "aws_wafv2_web_acl_association" "this" {
  for_each = var.scope == "REGIONAL" ? toset(var.resource_arns) : toset([])

  resource_arn = each.value
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

###############################################################################
# CloudWatch Log Group for WAF Logging
###############################################################################

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${local.name_prefix}-${var.name}"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "aws-waf-logs-${local.name_prefix}-${var.name}"
  })
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
}
