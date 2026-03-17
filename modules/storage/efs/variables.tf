variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 32
    error_message = "Project name must be between 1 and 32 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "uat", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, uat, sandbox."
  }
}

variable "performance_mode" {
  description = "EFS performance mode (generalPurpose or maxIO)"
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Must be generalPurpose or maxIO."
  }
}

variable "throughput_mode" {
  description = "EFS throughput mode (bursting, provisioned, or elastic)"
  type        = string
  default     = "elastic"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "Must be bursting, provisioned, or elastic."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "Provisioned throughput in MiB/s (required when throughput_mode is provisioned)"
  type        = number
  default     = null

  validation {
    condition     = var.provisioned_throughput_in_mibps == null || (var.provisioned_throughput_in_mibps >= 1 && var.provisioned_throughput_in_mibps <= 3414)
    error_message = "Must be between 1 and 3414 MiB/s."
  }
}

variable "encrypted" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for mount targets"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID is required."
  }
}

variable "security_group_ids" {
  description = "Security group IDs for mount targets"
  type        = list(string)
  default     = []
}

variable "access_points" {
  description = "List of access point configurations"
  type = list(object({
    name = string
    posix_user = optional(object({
      uid            = number
      gid            = number
      secondary_gids = optional(list(number))
    }))
    root_directory = optional(object({
      path = string
      creation_info = optional(object({
        owner_uid   = number
        owner_gid   = number
        permissions = string
      }))
    }))
  }))
  default = []
}

variable "lifecycle_policy_transition_to_ia" {
  description = "Transition to IA storage class after N days (AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS, AFTER_1_DAY)"
  type        = string
  default     = "AFTER_30_DAYS"

  validation {
    condition     = var.lifecycle_policy_transition_to_ia == null || contains(["AFTER_1_DAY", "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS"], var.lifecycle_policy_transition_to_ia)
    error_message = "Must be a valid transition period."
  }
}

variable "lifecycle_policy_transition_to_primary" {
  description = "Transition back to primary storage (AFTER_1_ACCESS)"
  type        = string
  default     = "AFTER_1_ACCESS"

  validation {
    condition     = var.lifecycle_policy_transition_to_primary == null || var.lifecycle_policy_transition_to_primary == "AFTER_1_ACCESS"
    error_message = "Must be AFTER_1_ACCESS or null."
  }
}

variable "enable_backup" {
  description = "Enable automatic backups via AWS Backup"
  type        = bool
  default     = true
}

variable "team" {
  description = "Team name for resource tagging"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center for resource tagging"
  type        = string
  default     = ""
}

variable "repository" {
  description = "Repository URL for resource tagging"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
