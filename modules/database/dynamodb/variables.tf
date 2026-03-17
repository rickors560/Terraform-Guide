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

variable "table_name_suffix" {
  description = "Suffix for the DynamoDB table name"
  type        = string

  validation {
    condition     = length(var.table_name_suffix) > 0
    error_message = "Table name suffix must not be empty."
  }
}

variable "billing_mode" {
  description = "Billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "read_capacity" {
  description = "Read capacity units (only for PROVISIONED billing mode)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units (only for PROVISIONED billing mode)"
  type        = number
  default     = 5
}

variable "hash_key" {
  description = "Hash (partition) key name"
  type        = string

  validation {
    condition     = length(var.hash_key) > 0
    error_message = "Hash key must not be empty."
  }
}

variable "hash_key_type" {
  description = "Hash key type (S, N, B)"
  type        = string
  default     = "S"

  validation {
    condition     = contains(["S", "N", "B"], var.hash_key_type)
    error_message = "Must be S, N, or B."
  }
}

variable "range_key" {
  description = "Range (sort) key name"
  type        = string
  default     = null
}

variable "range_key_type" {
  description = "Range key type (S, N, B)"
  type        = string
  default     = "S"

  validation {
    condition     = contains(["S", "N", "B"], var.range_key_type)
    error_message = "Must be S, N, or B."
  }
}

variable "ttl_attribute" {
  description = "TTL attribute name (leave empty to disable)"
  type        = string
  default     = ""
}

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "server_side_encryption_enabled" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "server_side_encryption_kms_key_arn" {
  description = "KMS key ARN for server-side encryption (uses AWS owned key if null)"
  type        = string
  default     = null
}

variable "stream_enabled" {
  description = "Enable DynamoDB Streams"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Stream view type (KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES)"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"

  validation {
    condition     = contains(["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"], var.stream_view_type)
    error_message = "Must be a valid stream view type."
  }
}

variable "global_secondary_indexes" {
  description = "List of global secondary indexes"
  type = list(object({
    name               = string
    hash_key           = string
    hash_key_type      = string
    range_key          = optional(string)
    range_key_type     = optional(string)
    projection_type    = string
    non_key_attributes = optional(list(string))
    read_capacity      = optional(number)
    write_capacity     = optional(number)
  }))
  default = []
}

variable "local_secondary_indexes" {
  description = "List of local secondary indexes"
  type = list(object({
    name               = string
    range_key          = string
    range_key_type     = string
    projection_type    = string
    non_key_attributes = optional(list(string))
  }))
  default = []
}

variable "enable_autoscaling" {
  description = "Enable auto scaling for PROVISIONED billing mode"
  type        = bool
  default     = false
}

variable "autoscaling_read_min_capacity" {
  description = "Minimum read capacity for auto scaling"
  type        = number
  default     = 5
}

variable "autoscaling_read_max_capacity" {
  description = "Maximum read capacity for auto scaling"
  type        = number
  default     = 100
}

variable "autoscaling_write_min_capacity" {
  description = "Minimum write capacity for auto scaling"
  type        = number
  default     = 5
}

variable "autoscaling_write_max_capacity" {
  description = "Maximum write capacity for auto scaling"
  type        = number
  default     = 100
}

variable "autoscaling_target_value" {
  description = "Target utilization percentage for auto scaling"
  type        = number
  default     = 70
}

variable "deletion_protection_enabled" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
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
