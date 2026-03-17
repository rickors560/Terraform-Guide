provider "aws" {
  region = var.aws_region
}

module "dashboard" {
  source = "../../"

  project        = var.project
  environment    = var.environment
  dashboard_name = "application-overview"
  default_period = 300
  default_stat   = "Average"

  widgets = [
    {
      type     = "text"
      x        = 0
      y        = 0
      width    = 24
      height   = 1
      markdown = "# ${var.project} - ${var.environment} Dashboard"
    },
    {
      type   = "metric"
      x      = 0
      y      = 1
      width  = 12
      height = 6
      title  = "EC2 CPU Utilization"
      metrics = [
        ["AWS/EC2", "CPUUtilization", "InstanceId", var.instance_id]
      ]
    },
    {
      type   = "metric"
      x      = 12
      y      = 1
      width  = 12
      height = 6
      title  = "EC2 Network In/Out"
      metrics = [
        ["AWS/EC2", "NetworkIn", "InstanceId", var.instance_id],
        ["AWS/EC2", "NetworkOut", "InstanceId", var.instance_id]
      ]
    },
    {
      type       = "alarm"
      x          = 0
      y          = 7
      width      = 24
      height     = 3
      title      = "Alarm Status"
      alarm_arns = var.alarm_arns
    },
  ]

  additional_tags = {
    Example = "complete"
  }
}
