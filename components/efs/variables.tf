# -----------------------------------------------------------------------------
# EFS Component - Variables
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "vpc_id" {
  description = "VPC ID for the EFS security group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EFS mount targets"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to access EFS via NFS"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access EFS via NFS"
  type        = list(string)
  default     = []
}

variable "performance_mode" {
  description = "EFS performance mode: generalPurpose or maxIO"
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Performance mode must be generalPurpose or maxIO."
  }
}

variable "throughput_mode" {
  description = "EFS throughput mode: bursting, provisioned, or elastic"
  type        = string
  default     = "elastic"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "Throughput mode must be bursting, provisioned, or elastic."
  }
}

variable "provisioned_throughput" {
  description = "Provisioned throughput in MiB/s (only used when throughput_mode is provisioned)"
  type        = number
  default     = 256
}

variable "transition_to_ia" {
  description = "Lifecycle policy for transitioning files to Infrequent Access"
  type        = string
  default     = "AFTER_30_DAYS"

  validation {
    condition = contains([
      "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS",
      "AFTER_60_DAYS", "AFTER_90_DAYS"
    ], var.transition_to_ia)
    error_message = "Must be one of: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS."
  }
}

variable "enable_backup" {
  description = "Whether to enable automatic backups"
  type        = bool
  default     = true
}
