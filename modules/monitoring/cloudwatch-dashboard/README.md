# CloudWatch Dashboard Module

Terraform module to create AWS CloudWatch Dashboards with configurable widgets or raw JSON body.

## Features

- Dashboard creation from widget variable definitions or raw JSON
- Metric, text, log, and alarm widget types
- Configurable default period and statistic
- Automatic region detection for widgets
- Consistent naming and tagging

## Usage

```hcl
module "dashboard" {
  source = "../../modules/monitoring/cloudwatch-dashboard"

  project        = "myapp"
  environment    = "prod"
  dashboard_name = "overview"
  default_period = 300
  default_stat   = "Average"

  widgets = [
    {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      title  = "CPU Utilization"
      metrics = [
        ["AWS/EC2", "CPUUtilization", "InstanceId", "i-xxx"]
      ]
    },
    {
      type     = "text"
      x        = 0
      y        = 6
      width    = 24
      height   = 2
      markdown = "## Application Metrics"
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| dashboard_name | Dashboard name suffix | string | - | yes |
| dashboard_body_json | Raw JSON dashboard body | string | null | no |
| widgets | List of widget configurations | list(object) | [] | no |
| default_period | Default metric period in seconds | number | 300 | no |
| default_stat | Default statistic | string | "Average" | no |

## Outputs

| Name | Description |
|------|-------------|
| dashboard_name | Name of the dashboard |
| dashboard_arn | ARN of the dashboard |
