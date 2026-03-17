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
  description = "Short name for the secret (appended to name_prefix)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_+=.@-]+$", var.name))
    error_message = "Secret name must contain only valid characters."
  }
}

variable "description" {
  description = "Description of the secret."
  type        = string
  default     = "Managed by Terraform"
}

variable "kms_key_id" {
  description = "KMS key ID or ARN to encrypt the secret. Uses AWS managed key if null."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Number of days before permanent deletion (0 for immediate, 7-30 for recovery window)."
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "Recovery window must be 0 (immediate deletion) or between 7 and 30 days."
  }
}

variable "secret_string" {
  description = "Initial secret string value. Changes are ignored after creation."
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_binary" {
  description = "Initial secret binary value (base64-encoded). Changes are ignored after creation."
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_rotation" {
  description = "Whether to enable automatic rotation."
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function for secret rotation."
  type        = string
  default     = null
}

variable "rotation_days" {
  description = "Number of days between automatic rotations."
  type        = number
  default     = 30

  validation {
    condition     = var.rotation_days >= 1 && var.rotation_days <= 365
    error_message = "Rotation days must be between 1 and 365."
  }
}

variable "replica_regions" {
  description = "List of regions to replicate the secret to."
  type = list(object({
    region     = string
    kms_key_id = optional(string, null)
  }))
  default = []
}

variable "policy" {
  description = "Resource-based policy JSON for the secret."
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
