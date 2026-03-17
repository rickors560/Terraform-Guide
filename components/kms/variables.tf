# -----------------------------------------------------------------------------
# KMS Component - Variables
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.project_name))
    error_message = "Project name must be 3-30 characters, lowercase alphanumeric with hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "deletion_window_in_days" {
  description = "Number of days before a KMS key is permanently deleted (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "rotation_period_in_days" {
  description = "Number of days between automatic key rotations (90-2560)"
  type        = number
  default     = 365

  validation {
    condition     = var.rotation_period_in_days >= 90 && var.rotation_period_in_days <= 2560
    error_message = "Rotation period must be between 90 and 2560 days."
  }
}

variable "enable_multi_region" {
  description = "Whether to create multi-region primary keys"
  type        = bool
  default     = false
}

variable "key_admin_arns" {
  description = "List of IAM ARNs that can administer the KMS keys"
  type        = list(string)
  default     = []
}

variable "key_user_arns" {
  description = "List of IAM ARNs that can use the KMS keys for encryption/decryption"
  type        = list(string)
  default     = []
}

variable "allowed_service_principals" {
  description = "List of AWS service principals allowed to use the general-purpose key"
  type        = list(string)
  default = [
    "logs.amazonaws.com",
    "sns.amazonaws.com",
    "sqs.amazonaws.com"
  ]
}

variable "kms_grants" {
  description = "Map of KMS grants to create on the general-purpose key"
  type = map(object({
    grantee_principal         = string
    operations                = list(string)
    encryption_context_subset = optional(map(string))
  }))
  default = {}
}
