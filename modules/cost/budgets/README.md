# AWS Budgets Module

Terraform module to create and manage AWS Budgets with notifications and auto-adjustment.

## Features

- Cost, usage, and reservation budget types
- Configurable time periods (monthly, quarterly, annually)
- Cost filters by service, linked account, or tag
- Multiple notification thresholds with email and SNS subscribers
- Actual and forecasted notification types
- Auto-adjustment based on historical data
- Detailed cost type configuration
- Consistent naming and tagging

## Usage

```hcl
module "budgets" {
  source = "../../modules/cost/budgets"

  project     = "myapp"
  environment = "prod"

  budgets = [
    {
      name         = "monthly-total"
      limit_amount = "1000"
      time_unit    = "MONTHLY"

      notifications = [
        {
          comparison_operator        = "GREATER_THAN"
          threshold                  = 80
          notification_type          = "ACTUAL"
          subscriber_email_addresses = ["finance@example.com"]
        },
        {
          comparison_operator        = "GREATER_THAN"
          threshold                  = 100
          notification_type          = "FORECASTED"
          subscriber_email_addresses = ["finance@example.com", "cto@example.com"]
        }
      ]
    },
    {
      name         = "ec2-monthly"
      limit_amount = "500"
      time_unit    = "MONTHLY"
      cost_filters = {
        Service = ["Amazon Elastic Compute Cloud - Compute"]
      }
      notifications = [
        {
          comparison_operator        = "GREATER_THAN"
          threshold                  = 90
          notification_type          = "ACTUAL"
          subscriber_email_addresses = ["ops@example.com"]
        }
      ]
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
| budgets | List of budget configurations | list(object) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| budget_ids | Map of budget names to IDs |
| budget_arns | Map of budget names to ARNs |
