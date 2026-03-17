# -----------------------------------------------------------------------------
# Budgets Component - Monthly Cost Budget with Threshold Notifications
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/budgets/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "budgets"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# Overall Monthly Cost Budget
# -----------------------------------------------------------------------------

resource "aws_budgets_budget" "monthly_cost" {
  name         = "${local.name_prefix}-monthly-cost"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "TagKeyValue"
    values = ["user:Project$${var.project_name}"]
  }

  cost_types {
    include_credit             = false
    include_discount           = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = false
    include_subscription       = true
    include_support            = true
    include_tax                = true
    include_upfront            = true
    use_blended                = false
  }

  # 50% threshold notification
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
    subscriber_sns_topic_arns  = var.budget_sns_topic_arns
  }

  # 80% threshold notification
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
    subscriber_sns_topic_arns  = var.budget_sns_topic_arns
  }

  # 100% threshold notification
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
    subscriber_sns_topic_arns  = var.budget_sns_topic_arns
  }

  # Forecasted to exceed budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_notification_emails
    subscriber_sns_topic_arns  = var.budget_sns_topic_arns
  }

  tags = {
    Name = "${local.name_prefix}-monthly-cost"
  }
}

# -----------------------------------------------------------------------------
# EC2 Service Budget
# -----------------------------------------------------------------------------

resource "aws_budgets_budget" "ec2" {
  name         = "${local.name_prefix}-ec2-budget"
  budget_type  = "COST"
  limit_amount = var.ec2_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "Service"
    values = ["Amazon Elastic Compute Cloud - Compute"]
  }

  cost_types {
    include_credit             = false
    include_discount           = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = false
    include_subscription       = true
    include_support            = false
    include_tax                = true
    include_upfront            = true
    use_blended                = false
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
    subscriber_sns_topic_arns  = var.budget_sns_topic_arns
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
    subscriber_sns_topic_arns  = var.budget_sns_topic_arns
  }

  tags = {
    Name = "${local.name_prefix}-ec2-budget"
  }
}

# -----------------------------------------------------------------------------
# RDS Service Budget
# -----------------------------------------------------------------------------

resource "aws_budgets_budget" "rds" {
  name         = "${local.name_prefix}-rds-budget"
  budget_type  = "COST"
  limit_amount = var.rds_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "Service"
    values = ["Amazon Relational Database Service"]
  }

  cost_types {
    include_credit             = false
    include_discount           = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = false
    include_subscription       = true
    include_support            = false
    include_tax                = true
    include_upfront            = true
    use_blended                = false
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
    subscriber_sns_topic_arns  = var.budget_sns_topic_arns
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_notification_emails
    subscriber_sns_topic_arns  = var.budget_sns_topic_arns
  }

  tags = {
    Name = "${local.name_prefix}-rds-budget"
  }
}

# -----------------------------------------------------------------------------
# Data Transfer Budget
# -----------------------------------------------------------------------------

resource "aws_budgets_budget" "data_transfer" {
  name         = "${local.name_prefix}-data-transfer-budget"
  budget_type  = "COST"
  limit_amount = var.data_transfer_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "UsageType"
    values = ["DataTransfer-Out-Bytes"]
  }

  cost_types {
    include_credit             = false
    include_discount           = true
    include_other_subscription = false
    include_recurring          = true
    include_refund             = false
    include_subscription       = false
    include_support            = false
    include_tax                = true
    include_upfront            = false
    use_blended                = false
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
    subscriber_sns_topic_arns  = var.budget_sns_topic_arns
  }

  tags = {
    Name = "${local.name_prefix}-data-transfer-budget"
  }
}
