################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id
  log_group_class   = var.log_group_class
  skip_destroy      = var.skip_destroy

  tags = local.common_tags
}

################################################################################
# Metric Filters
################################################################################

resource "aws_cloudwatch_log_metric_filter" "this" {
  for_each = local.metric_filters_map

  name           = "${local.name_prefix}-${each.value.name}"
  log_group_name = aws_cloudwatch_log_group.this.name
  pattern        = each.value.pattern

  metric_transformation {
    namespace     = each.value.metric_namespace
    name          = each.value.metric_name
    value         = each.value.metric_value
    default_value = each.value.default_value
    unit          = each.value.unit
    dimensions    = each.value.dimensions
  }
}

################################################################################
# Subscription Filters
################################################################################

resource "aws_cloudwatch_log_subscription_filter" "this" {
  for_each = local.subscription_filters_map

  name            = "${local.name_prefix}-${each.value.name}"
  log_group_name  = aws_cloudwatch_log_group.this.name
  filter_pattern  = each.value.filter_pattern
  destination_arn = each.value.destination_arn
  role_arn        = each.value.role_arn
  distribution    = each.value.distribution
}
