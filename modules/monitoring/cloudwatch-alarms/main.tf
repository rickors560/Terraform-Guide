################################################################################
# CloudWatch Metric Alarms
################################################################################

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms_map

  alarm_name          = "${local.name_prefix}-${each.value.alarm_name}"
  alarm_description   = each.value.alarm_description
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  statistic           = each.value.extended_statistic == null ? each.value.statistic : null
  extended_statistic  = each.value.extended_statistic
  period              = each.value.period
  threshold           = each.value.threshold
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  datapoints_to_alarm = each.value.datapoints_to_alarm != null ? each.value.datapoints_to_alarm : each.value.evaluation_periods
  treat_missing_data  = each.value.treat_missing_data
  unit                = each.value.unit
  actions_enabled     = each.value.actions_enabled

  dimensions = each.value.dimensions

  alarm_actions = coalescelist(
    each.value.alarm_actions,
    var.default_alarm_actions,
    var.default_sns_topic_arn != "" ? [var.default_sns_topic_arn] : [],
  )

  ok_actions = coalescelist(
    each.value.ok_actions,
    var.default_ok_actions,
    var.default_sns_topic_arn != "" ? [var.default_sns_topic_arn] : [],
  )

  insufficient_data_actions = coalescelist(
    each.value.insufficient_data_actions,
    var.default_insufficient_data_actions,
  )

  tags = merge(local.common_tags, each.value.tags)
}

################################################################################
# CloudWatch Composite Alarms
################################################################################

resource "aws_cloudwatch_composite_alarm" "this" {
  for_each = { for alarm in var.composite_alarms : alarm.alarm_name => alarm }

  alarm_name        = "${local.name_prefix}-${each.value.alarm_name}"
  alarm_description = each.value.alarm_description
  alarm_rule        = each.value.alarm_rule
  actions_enabled   = each.value.actions_enabled

  alarm_actions = coalescelist(
    each.value.alarm_actions,
    var.default_alarm_actions,
    var.default_sns_topic_arn != "" ? [var.default_sns_topic_arn] : [],
  )

  ok_actions = coalescelist(
    each.value.ok_actions,
    var.default_ok_actions,
    var.default_sns_topic_arn != "" ? [var.default_sns_topic_arn] : [],
  )

  insufficient_data_actions = coalescelist(
    each.value.insufficient_data_actions,
    var.default_insufficient_data_actions,
  )

  tags = merge(local.common_tags, each.value.tags)

  depends_on = [aws_cloudwatch_metric_alarm.this]
}
