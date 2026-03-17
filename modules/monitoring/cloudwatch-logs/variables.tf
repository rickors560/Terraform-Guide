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

variable "component" {
  description = "Component name used in the log group name when log_group_name is not explicitly set."
  type        = string
  default     = "application"
}

variable "log_group_name" {
  description = "Explicit name for the CloudWatch Log Group. If empty, defaults to /{project}-{environment}/{component}."
  type        = string
  default     = ""
}

variable "retention_in_days" {
  description = "Number of days to retain log events in the log group."
  type        = number
  default     = 30

  validation {
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.retention_in_days
    )
    error_message = "Retention days must be a valid CloudWatch Logs retention value: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653."
  }
}

variable "kms_key_id" {
  description = "ARN of the KMS key to use for encrypting log data. Leave empty for no encryption."
  type        = string
  default     = null
}

variable "log_group_class" {
  description = "Log group class. Valid values are STANDARD or INFREQUENT_ACCESS."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "INFREQUENT_ACCESS"], var.log_group_class)
    error_message = "Log group class must be STANDARD or INFREQUENT_ACCESS."
  }
}

variable "skip_destroy" {
  description = "Set to true to prevent the log group from being deleted on terraform destroy."
  type        = bool
  default     = false
}

variable "metric_filters" {
  description = "List of metric filter configurations for the log group."
  type = list(object({
    name           = string
    pattern        = string
    metric_namespace = string
    metric_name    = string
    metric_value   = string
    default_value  = optional(string, null)
    unit           = optional(string, null)
    dimensions     = optional(map(string), {})
  }))
  default = []
}

variable "subscription_filters" {
  description = "List of subscription filter configurations for the log group."
  type = list(object({
    name            = string
    filter_pattern  = string
    destination_arn = string
    role_arn        = optional(string, null)
    distribution    = optional(string, "ByLogStream")
  }))
  default = []

  validation {
    condition = alltrue([
      for sf in var.subscription_filters : contains(["Random", "ByLogStream"], sf.distribution)
    ])
    error_message = "Subscription filter distribution must be Random or ByLogStream."
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
