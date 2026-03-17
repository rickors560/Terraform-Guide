provider "aws" {
  region = var.aws_region
}

module "budgets" {
  source = "../../"

  project     = var.project
  environment = var.environment

  budgets = [
    {
      name         = "monthly-total"
      budget_type  = "COST"
      limit_amount = "5000"
      limit_unit   = "USD"
      time_unit    = "MONTHLY"

      notifications = [
        {
          comparison_operator        = "GREATER_THAN"
          threshold                  = 50
          threshold_type             = "PERCENTAGE"
          notification_type          = "ACTUAL"
          subscriber_email_addresses = [var.finance_email]
        },
        {
          comparison_operator        = "GREATER_THAN"
          threshold                  = 80
          threshold_type             = "PERCENTAGE"
          notification_type          = "ACTUAL"
          subscriber_email_addresses = [var.finance_email, var.ops_email]
        },
        {
          comparison_operator        = "GREATER_THAN"
          threshold                  = 100
          threshold_type             = "PERCENTAGE"
          notification_type          = "FORECASTED"
          subscriber_email_addresses = [var.finance_email, var.ops_email]
          subscriber_sns_topic_arns  = var.sns_topic_arns
        },
      ]
    },
    {
      name         = "ec2-monthly"
      budget_type  = "COST"
      limit_amount = "2000"
      time_unit    = "MONTHLY"

      cost_filters = {
        Service = ["Amazon Elastic Compute Cloud - Compute"]
      }

      notifications = [
        {
          comparison_operator        = "GREATER_THAN"
          threshold                  = 90
          notification_type          = "ACTUAL"
          subscriber_email_addresses = [var.ops_email]
        }
      ]
    },
    {
      name         = "quarterly-total"
      budget_type  = "COST"
      limit_amount = "15000"
      time_unit    = "QUARTERLY"

      auto_adjust_data = {
        auto_adjust_type = "HISTORICAL"
        historical_options = {
          budget_adjustment_period = 4
        }
      }

      notifications = [
        {
          comparison_operator        = "GREATER_THAN"
          threshold                  = 100
          notification_type          = "FORECASTED"
          subscriber_email_addresses = [var.finance_email]
        }
      ]
    },
  ]

  additional_tags = {
    Example = "complete"
  }
}
