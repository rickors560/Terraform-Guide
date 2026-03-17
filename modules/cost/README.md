# Cost Management Modules

Terraform modules for AWS cost visibility and budget management including AWS Budgets and Cost and Usage Reports.

## Sub-Modules

| Module | Description |
|--------|-------------|
| [budgets](./budgets/) | AWS Budgets with notifications and auto-adjustment for cost and usage tracking |
| [cur](./cur/) | Cost and Usage Reports with S3 bucket storage for detailed billing analysis |

## How They Relate

```
cur (detailed billing data) --> S3 bucket --> Athena / QuickSight (analysis)

budgets (threshold alerts) --> SNS / Email (notifications)
```

- **budgets** sets spending thresholds and sends alerts when actual or forecasted costs exceed limits. Useful for proactive cost control.
- **cur** generates detailed hourly/daily cost and usage data delivered to an S3 bucket. This data can be queried with Athena or visualized in QuickSight for in-depth cost analysis.

Together, **budgets** provides real-time alerting while **cur** provides the raw data for retrospective analysis and optimization.

## Usage Example

```hcl
module "monthly_budget" {
  source = "../../modules/cost/budgets"

  project     = "myapp"
  environment = "prod"

  budgets = [
    {
      name         = "monthly-total"
      budget_type  = "COST"
      limit_amount = "5000"
      limit_unit   = "USD"
      time_unit    = "MONTHLY"

      notifications = [
        {
          comparison_operator = "GREATER_THAN"
          threshold           = 80
          threshold_type      = "PERCENTAGE"
          notification_type   = "ACTUAL"
          subscriber_email_addresses = ["finance@example.com"]
        },
        {
          comparison_operator = "GREATER_THAN"
          threshold           = 100
          threshold_type      = "PERCENTAGE"
          notification_type   = "FORECASTED"
          subscriber_email_addresses = ["finance@example.com", "oncall@example.com"]
        }
      ]
    }
  ]

  team = "platform"
}

module "cost_report" {
  source = "../../modules/cost/cur"

  project     = "myapp"
  environment = "prod"

  s3_bucket_name = module.cur_bucket.bucket_name
  time_unit      = "HOURLY"

  team = "platform"
}
```
