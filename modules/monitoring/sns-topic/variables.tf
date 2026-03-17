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

variable "name" {
  description = "Name suffix for the SNS topic."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.name))
    error_message = "Topic name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "display_name" {
  description = "Display name for the SNS topic."
  type        = string
  default     = ""
}

variable "fifo_topic" {
  description = "Whether to create a FIFO topic."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO topics."
  type        = bool
  default     = false
}

variable "kms_master_key_id" {
  description = "ARN of the KMS key for SNS topic encryption. Use 'alias/aws/sns' for AWS managed key."
  type        = string
  default     = null
}

variable "signature_version" {
  description = "Signature version for SNS topic. Valid values: 1, 2."
  type        = number
  default     = null

  validation {
    condition     = var.signature_version == null || contains([1, 2], var.signature_version)
    error_message = "Signature version must be 1 or 2."
  }
}

variable "tracing_config" {
  description = "Tracing mode for the SNS topic. Valid values: PassThrough, Active."
  type        = string
  default     = null

  validation {
    condition     = var.tracing_config == null || contains(["PassThrough", "Active"], var.tracing_config)
    error_message = "Tracing config must be PassThrough or Active."
  }
}

variable "delivery_policy" {
  description = "SNS delivery policy JSON string."
  type        = string
  default     = null
}

variable "policy" {
  description = "SNS topic access policy JSON string. If not provided, the default AWS policy is used."
  type        = string
  default     = null
}

variable "subscriptions" {
  description = "List of SNS topic subscriptions."
  type = list(object({
    protocol                        = string
    endpoint                        = string
    endpoint_auto_confirms          = optional(bool, false)
    raw_message_delivery            = optional(bool, false)
    filter_policy                   = optional(string, null)
    filter_policy_scope             = optional(string, null)
    redrive_policy                  = optional(string, null)
    delivery_policy                 = optional(string, null)
    subscription_role_arn           = optional(string, null)
    confirmation_timeout_in_minutes = optional(number, null)
  }))
  default = []

  validation {
    condition = alltrue([
      for sub in var.subscriptions : contains(
        ["email", "email-json", "sms", "sqs", "lambda", "https", "http", "application", "firehose"],
        sub.protocol
      )
    ])
    error_message = "Subscription protocol must be one of: email, email-json, sms, sqs, lambda, https, http, application, firehose."
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
