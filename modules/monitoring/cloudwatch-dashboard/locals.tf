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

  dashboard_name = "${local.name_prefix}-${var.dashboard_name}"

  # Build widgets from the variable definitions when dashboard_body_json is not provided
  constructed_widgets = [
    for widget in var.widgets : {
      type   = widget.type
      x      = widget.x
      y      = widget.y
      width  = widget.width
      height = widget.height
      properties = merge(
        widget.type == "metric" ? {
          metrics = widget.metrics
          period  = coalesce(widget.period, var.default_period)
          stat    = coalesce(widget.stat, var.default_stat)
          region  = coalesce(widget.region, data.aws_region.current.name)
          title   = widget.title
          view    = widget.view
          stacked = widget.stacked
          yAxis   = widget.y_axis
        } : {},
        widget.type == "text" ? {
          markdown = widget.markdown
        } : {},
        widget.type == "log" ? {
          query  = widget.query
          region = coalesce(widget.region, data.aws_region.current.name)
          title  = widget.title
          view   = widget.view
        } : {},
        widget.type == "alarm" ? {
          alarms = widget.alarm_arns
          title  = widget.title
          sortBy = widget.sort_by
          states = widget.states
        } : {},
      )
    }
  ]

  # Use provided JSON body or construct from widgets
  dashboard_body = var.dashboard_body_json != null ? var.dashboard_body_json : jsonencode({
    widgets = local.constructed_widgets
  })
}

data "aws_region" "current" {}
