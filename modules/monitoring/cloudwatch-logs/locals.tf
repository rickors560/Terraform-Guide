locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Team        = var.team
      CostCenter  = var.cost_center
      Repository  = var.repository
    },
    var.additional_tags,
  )

  log_group_name = var.log_group_name != "" ? var.log_group_name : "/${local.name_prefix}/${var.component}"

  metric_filters_map = { for mf in var.metric_filters : mf.name => mf }

  subscription_filters_map = { for sf in var.subscription_filters : sf.name => sf }
}
