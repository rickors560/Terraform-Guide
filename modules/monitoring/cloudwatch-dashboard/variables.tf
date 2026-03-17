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

variable "dashboard_name" {
  description = "Name suffix for the CloudWatch Dashboard."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.dashboard_name))
    error_message = "Dashboard name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "dashboard_body_json" {
  description = "Complete dashboard body as a JSON string. When provided, the widgets variable is ignored."
  type        = string
  default     = null
}

variable "default_period" {
  description = "Default period in seconds for metric widgets."
  type        = number
  default     = 300

  validation {
    condition     = contains([10, 30, 60, 300, 900, 3600, 21600, 86400], var.default_period)
    error_message = "Default period must be one of: 10, 30, 60, 300, 900, 3600, 21600, 86400."
  }
}

variable "default_stat" {
  description = "Default statistic for metric widgets."
  type        = string
  default     = "Average"

  validation {
    condition     = contains(["Average", "Sum", "Minimum", "Maximum", "SampleCount", "p50", "p90", "p95", "p99"], var.default_stat)
    error_message = "Default stat must be a valid CloudWatch statistic."
  }
}

variable "widgets" {
  description = "List of widget configurations for the dashboard. Ignored when dashboard_body_json is provided."
  type = list(object({
    type   = string
    x      = number
    y      = number
    width  = number
    height = number
    title  = optional(string, "")

    # Metric widget properties
    metrics = optional(list(any), [])
    period  = optional(number, null)
    stat    = optional(string, null)
    region  = optional(string, null)
    view    = optional(string, "timeSeries")
    stacked = optional(bool, false)
    y_axis  = optional(map(any), {})

    # Text widget properties
    markdown = optional(string, "")

    # Log widget properties
    query = optional(string, "")

    # Alarm widget properties
    alarm_arns = optional(list(string), [])
    sort_by    = optional(string, "stateUpdatedTimestamp")
    states     = optional(list(string), ["ALARM", "INSUFFICIENT_DATA", "OK"])
  }))
  default = []

  validation {
    condition = alltrue([
      for w in var.widgets : contains(["metric", "text", "log", "alarm"], w.type)
    ])
    error_message = "Widget type must be one of: metric, text, log, alarm."
  }

  validation {
    condition = alltrue([
      for w in var.widgets : w.width >= 1 && w.width <= 24
    ])
    error_message = "Widget width must be between 1 and 24."
  }

  validation {
    condition = alltrue([
      for w in var.widgets : w.height >= 1 && w.height <= 1000
    ])
    error_message = "Widget height must be between 1 and 1000."
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
