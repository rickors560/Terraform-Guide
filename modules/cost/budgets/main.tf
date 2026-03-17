################################################################################
# AWS Budgets
################################################################################

resource "aws_budgets_budget" "this" {
  for_each = local.budgets_map

  name         = "${local.name_prefix}-${each.value.name}"
  budget_type  = each.value.budget_type
  limit_amount = each.value.limit_amount
  limit_unit   = each.value.limit_unit
  time_unit    = each.value.time_unit

  time_period_start = each.value.time_period_start
  time_period_end   = each.value.time_period_end

  dynamic "cost_filter" {
    for_each = each.value.cost_filters

    content {
      name   = cost_filter.key
      values = cost_filter.value
    }
  }

  cost_types {
    include_credit             = each.value.cost_types.include_credit
    include_discount           = each.value.cost_types.include_discount
    include_other_subscription = each.value.cost_types.include_other_subscription
    include_recurring          = each.value.cost_types.include_recurring
    include_refund             = each.value.cost_types.include_refund
    include_subscription       = each.value.cost_types.include_subscription
    include_support            = each.value.cost_types.include_support
    include_tax                = each.value.cost_types.include_tax
    include_upfront            = each.value.cost_types.include_upfront
    use_amortized              = each.value.cost_types.use_amortized
    use_blended                = each.value.cost_types.use_blended
  }

  dynamic "notification" {
    for_each = each.value.notifications

    content {
      comparison_operator        = notification.value.comparison_operator
      threshold                  = notification.value.threshold
      threshold_type             = notification.value.threshold_type
      notification_type          = notification.value.notification_type
      subscriber_email_addresses = notification.value.subscriber_email_addresses
      subscriber_sns_topic_arns  = notification.value.subscriber_sns_topic_arns
    }
  }

  dynamic "auto_adjust_data" {
    for_each = each.value.auto_adjust_data != null ? [each.value.auto_adjust_data] : []

    content {
      auto_adjust_type = auto_adjust_data.value.auto_adjust_type

      dynamic "historical_options" {
        for_each = auto_adjust_data.value.historical_options != null ? [auto_adjust_data.value.historical_options] : []

        content {
          budget_adjustment_period = historical_options.value.budget_adjustment_period
        }
      }
    }
  }

  tags = merge(local.common_tags, each.value.tags)
}
