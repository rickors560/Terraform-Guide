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

variable "metric_alarms" {
  description = "List of CloudWatch metric alarm configurations."
  type = list(object({
    alarm_name          = string
    alarm_description   = optional(string, "")
    namespace           = string
    metric_name         = string
    statistic           = optional(string, "Average")
    extended_statistic  = optional(string, null)
    period              = optional(number, 300)
    threshold           = number
    comparison_operator = string
    evaluation_periods  = optional(number, 1)
    datapoints_to_alarm = optional(number, null)
    treat_missing_data  = optional(string, "missing")
    dimensions          = optional(map(string), {})
    unit                = optional(string, null)
    actions_enabled     = optional(bool, true)
    alarm_actions       = optional(list(string), [])
    ok_actions          = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    tags                = optional(map(string), {})
  }))
  default = []

  validation {
    condition = alltrue([
      for alarm in var.metric_alarms : contains(
        ["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold", "LessThanLowerOrGreaterThanUpperThreshold", "LessThanLowerThreshold", "GreaterThanUpperThreshold"],
        alarm.comparison_operator
      )
    ])
    error_message = "Each alarm comparison_operator must be a valid CloudWatch comparison operator."
  }

  validation {
    condition = alltrue([
      for alarm in var.metric_alarms : contains(["missing", "ignore", "breaching", "notBreaching"], alarm.treat_missing_data)
    ])
    error_message = "treat_missing_data must be one of: missing, ignore, breaching, notBreaching."
  }
}

variable "default_sns_topic_arn" {
  description = "Default SNS topic ARN for alarm and OK actions. Applied to alarms that do not specify their own actions."
  type        = string
  default     = ""
}

variable "default_alarm_actions" {
  description = "Default list of ARNs to notify when alarm transitions to ALARM state."
  type        = list(string)
  default     = []
}

variable "default_ok_actions" {
  description = "Default list of ARNs to notify when alarm transitions to OK state."
  type        = list(string)
  default     = []
}

variable "default_insufficient_data_actions" {
  description = "Default list of ARNs to notify when alarm transitions to INSUFFICIENT_DATA state."
  type        = list(string)
  default     = []
}

variable "composite_alarms" {
  description = "List of composite alarm configurations."
  type = list(object({
    alarm_name        = string
    alarm_description = optional(string, "")
    alarm_rule        = string
    actions_enabled   = optional(bool, true)
    alarm_actions     = optional(list(string), [])
    ok_actions        = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    tags              = optional(map(string), {})
  }))
  default = []
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
