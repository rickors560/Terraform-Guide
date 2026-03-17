################################################################################
# Custom Event Bus
################################################################################

resource "aws_cloudwatch_event_bus" "this" {
  count = var.create_bus ? 1 : 0

  name = local.bus_name

  tags = merge(local.common_tags, {
    Name = local.bus_name
  })
}

################################################################################
# Event Bus Policy
################################################################################

resource "aws_cloudwatch_event_bus_policy" "this" {
  count = var.bus_policy != null ? 1 : 0

  event_bus_name = var.create_bus ? aws_cloudwatch_event_bus.this[0].name : var.bus_name
  policy         = var.bus_policy
}

################################################################################
# Event Rules
################################################################################

resource "aws_cloudwatch_event_rule" "this" {
  for_each = local.rules_map

  name                = "${local.name_prefix}-${each.value.name}"
  description         = each.value.description
  event_bus_name      = var.create_bus ? aws_cloudwatch_event_bus.this[0].name : var.bus_name
  event_pattern       = each.value.event_pattern
  schedule_expression = each.value.schedule_expression
  state               = each.value.state
  role_arn            = each.value.role_arn

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.value.name}"
  })
}

################################################################################
# Event Targets
################################################################################

resource "aws_cloudwatch_event_target" "this" {
  for_each = local.rule_targets_map

  rule           = aws_cloudwatch_event_rule.this[each.value.rule_name].name
  event_bus_name = var.create_bus ? aws_cloudwatch_event_bus.this[0].name : var.bus_name
  target_id      = each.value.target_id
  arn            = each.value.arn
  role_arn       = each.value.role_arn
  input          = each.value.input
  input_path     = each.value.input_path

  dynamic "input_transformer" {
    for_each = each.value.input_transformer != null ? [each.value.input_transformer] : []

    content {
      input_paths    = input_transformer.value.input_paths
      input_template = input_transformer.value.input_template
    }
  }

  dynamic "dead_letter_config" {
    for_each = each.value.dead_letter_arn != null ? [each.value.dead_letter_arn] : []

    content {
      arn = dead_letter_config.value
    }
  }

  dynamic "retry_policy" {
    for_each = each.value.retry_policy != null ? [each.value.retry_policy] : []

    content {
      maximum_event_age_in_seconds = retry_policy.value.maximum_event_age_in_seconds
      maximum_retry_attempts       = retry_policy.value.maximum_retry_attempts
    }
  }

  dynamic "sqs_target" {
    for_each = each.value.sqs_target != null ? [each.value.sqs_target] : []

    content {
      message_group_id = sqs_target.value.message_group_id
    }
  }

  dynamic "ecs_target" {
    for_each = each.value.ecs_target != null ? [each.value.ecs_target] : []

    content {
      task_definition_arn = ecs_target.value.task_definition_arn
      task_count          = ecs_target.value.task_count
      launch_type         = ecs_target.value.launch_type
      platform_version    = ecs_target.value.platform_version
      group               = ecs_target.value.group

      dynamic "network_configuration" {
        for_each = ecs_target.value.network_configuration != null ? [ecs_target.value.network_configuration] : []

        content {
          subnets          = network_configuration.value.subnets
          security_groups  = network_configuration.value.security_groups
          assign_public_ip = network_configuration.value.assign_public_ip
        }
      }
    }
  }
}

################################################################################
# Event Archives
################################################################################

resource "aws_cloudwatch_event_archive" "this" {
  for_each = { for archive in var.archives : archive.name => archive }

  name             = "${local.name_prefix}-${each.value.name}"
  description      = each.value.description
  event_source_arn = var.create_bus ? aws_cloudwatch_event_bus.this[0].arn : "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/${var.bus_name}"
  event_pattern    = each.value.event_pattern
  retention_days   = each.value.retention_days > 0 ? each.value.retention_days : null
}

################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
