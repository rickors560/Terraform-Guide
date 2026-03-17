variable "project" {
  description = "Project name used for resource naming and tagging."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "uat", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, uat, sandbox."
  }
}

variable "budgets" {
  description = "List of budget configurations."
  type = list(object({
    name         = string
    budget_type  = optional(string, "COST")
    limit_amount = string
    limit_unit   = optional(string, "USD")
    time_unit    = optional(string, "MONTHLY")

    time_period_start = optional(string, null)
    time_period_end   = optional(string, null)

    cost_filters = optional(map(list(string)), {})

    cost_types = optional(object({
      include_credit             = optional(bool, false)
      include_discount           = optional(bool, true)
      include_other_subscription = optional(bool, true)
      include_recurring          = optional(bool, true)
      include_refund             = optional(bool, false)
      include_subscription       = optional(bool, true)
      include_support            = optional(bool, true)
      include_tax                = optional(bool, true)
      include_upfront            = optional(bool, true)
      use_amortized              = optional(bool, false)
      use_blended                = optional(bool, false)
    }), {})

    notifications = list(object({
      comparison_operator        = string
      threshold                  = number
      threshold_type             = optional(string, "PERCENTAGE")
      notification_type          = string
      subscriber_email_addresses = optional(list(string), [])
      subscriber_sns_topic_arns  = optional(list(string), [])
    }))

    auto_adjust_data = optional(object({
      auto_adjust_type = string
      historical_options = optional(object({
        budget_adjustment_period = number
      }), null)
    }), null)

    tags = optional(map(string), {})
  }))
  default = []

  validation {
    condition = alltrue([
      for budget in var.budgets : contains(["MONTHLY", "QUARTERLY", "ANNUALLY"], budget.time_unit)
    ])
    error_message = "Budget time_unit must be MONTHLY, QUARTERLY, or ANNUALLY."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets : contains(["COST", "USAGE", "RI_UTILIZATION", "RI_COVERAGE", "SAVINGS_PLANS_UTILIZATION", "SAVINGS_PLANS_COVERAGE"], budget.budget_type)
    ])
    error_message = "Budget type must be COST, USAGE, RI_UTILIZATION, RI_COVERAGE, SAVINGS_PLANS_UTILIZATION, or SAVINGS_PLANS_COVERAGE."
  }

  validation {
    condition = alltrue(flatten([
      for budget in var.budgets : [
        for notification in budget.notifications : contains(["GREATER_THAN", "LESS_THAN", "EQUAL_TO"], notification.comparison_operator)
      ]
    ]))
    error_message = "Notification comparison_operator must be GREATER_THAN, LESS_THAN, or EQUAL_TO."
  }

  validation {
    condition = alltrue(flatten([
      for budget in var.budgets : [
        for notification in budget.notifications : contains(["ACTUAL", "FORECASTED"], notification.notification_type)
      ]
    ]))
    error_message = "Notification type must be ACTUAL or FORECASTED."
  }
}

variable "team" {
  description = "Team name for resource tagging."
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Cost center for resource tagging."
  type        = string
  default     = "infrastructure"
}

variable "repository" {
  description = "Repository URL for resource tagging."
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
