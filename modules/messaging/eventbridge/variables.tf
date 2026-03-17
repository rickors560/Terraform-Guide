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

variable "create_bus" {
  description = "Whether to create a custom event bus. If false, bus_name should be 'default' or an existing bus name."
  type        = bool
  default     = true
}

variable "bus_name" {
  description = "Name suffix for the custom event bus, or the name of an existing bus when create_bus is false."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._/-]+$", var.bus_name))
    error_message = "Bus name must contain only alphanumeric characters, periods, hyphens, underscores, or slashes."
  }
}

variable "bus_description" {
  description = "Description for the custom event bus."
  type        = string
  default     = null
}

variable "rules" {
  description = "List of EventBridge rule configurations with their targets."
  type = list(object({
    name                = string
    description         = optional(string, "")
    event_pattern       = optional(string, null)
    schedule_expression = optional(string, null)
    state               = optional(string, "ENABLED")
    role_arn            = optional(string, null)

    targets = list(object({
      target_id       = string
      arn             = string
      role_arn        = optional(string, null)
      input           = optional(string, null)
      input_path      = optional(string, null)
      dead_letter_arn = optional(string, null)

      input_transformer = optional(object({
        input_paths    = optional(map(string), null)
        input_template = string
      }), null)

      retry_policy = optional(object({
        maximum_event_age_in_seconds = optional(number, 86400)
        maximum_retry_attempts       = optional(number, 185)
      }), null)

      sqs_target = optional(object({
        message_group_id = string
      }), null)

      ecs_target = optional(object({
        task_definition_arn = string
        task_count          = optional(number, 1)
        launch_type         = optional(string, "FARGATE")
        platform_version    = optional(string, "LATEST")
        group               = optional(string, null)
        network_configuration = optional(object({
          subnets          = list(string)
          security_groups  = optional(list(string), [])
          assign_public_ip = optional(bool, false)
        }), null)
      }), null)
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.rules : contains(["ENABLED", "DISABLED"], rule.state)
    ])
    error_message = "Rule state must be ENABLED or DISABLED."
  }

  validation {
    condition = alltrue([
      for rule in var.rules : rule.event_pattern != null || rule.schedule_expression != null
    ])
    error_message = "Each rule must have either an event_pattern or a schedule_expression."
  }
}

variable "archives" {
  description = "List of event archives to create."
  type = list(object({
    name             = string
    description      = optional(string, "")
    event_pattern    = optional(string, null)
    retention_days   = optional(number, 0)
  }))
  default = []
}

variable "bus_policy" {
  description = "Resource-based policy for the event bus in JSON format."
  type        = string
  default     = null
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
