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

  # Build a map of alarms keyed by alarm name for easy lookup
  alarms_map = { for alarm in var.metric_alarms : alarm.alarm_name => alarm }
}
