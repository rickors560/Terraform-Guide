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

variable "trail_name" {
  description = "Name suffix for the CloudTrail trail."
  type        = string
  default     = "trail"
}

variable "is_multi_region_trail" {
  description = "Whether the trail is created in all regions."
  type        = bool
  default     = true
}

variable "is_organization_trail" {
  description = "Whether the trail is an AWS Organizations trail."
  type        = bool
  default     = false
}

variable "enable_log_file_validation" {
  description = "Whether log file integrity validation is enabled."
  type        = bool
  default     = true
}

variable "include_global_service_events" {
  description = "Whether the trail publishes events from global services such as IAM."
  type        = bool
  default     = true
}

variable "s3_key_prefix" {
  description = "S3 key prefix for CloudTrail log files."
  type        = string
  default     = "cloudtrail"
}

variable "create_s3_bucket" {
  description = "Whether to create an S3 bucket for CloudTrail logs."
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Name of an existing S3 bucket for CloudTrail logs. Required if create_s3_bucket is false."
  type        = string
  default     = ""
}

variable "s3_bucket_force_destroy" {
  description = "Whether to force destroy the S3 bucket on deletion."
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch Logs integration."
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention" {
  description = "Number of days to retain CloudWatch Logs."
  type        = number
  default     = 90

  validation {
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.cloudwatch_log_group_retention
    )
    error_message = "CloudWatch log retention must be a valid retention value."
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encrypting CloudTrail logs. If not set, SSE-S3 is used."
  type        = string
  default     = null
}

variable "enable_management_events" {
  description = "Whether to enable management event logging."
  type        = bool
  default     = true
}

variable "management_read_write_type" {
  description = "Type of management events to log. Valid values: ReadOnly, WriteOnly, All."
  type        = string
  default     = "All"

  validation {
    condition     = contains(["ReadOnly", "WriteOnly", "All"], var.management_read_write_type)
    error_message = "Management read_write_type must be ReadOnly, WriteOnly, or All."
  }
}

variable "management_exclude_sources" {
  description = "List of event sources to exclude from management event logging."
  type        = list(string)
  default     = []
}

variable "data_events" {
  description = "List of data event selectors for the trail."
  type = list(object({
    read_write_type           = optional(string, "All")
    include_management_events = optional(bool, false)
    data_resources = list(object({
      type   = string
      values = list(string)
    }))
  }))
  default = []
}

variable "insight_selectors" {
  description = "List of insight types to enable."
  type = list(object({
    insight_type = string
  }))
  default = []

  validation {
    condition = alltrue([
      for s in var.insight_selectors : contains(["ApiCallRateInsight", "ApiErrorRateInsight"], s.insight_type)
    ])
    error_message = "Insight type must be ApiCallRateInsight or ApiErrorRateInsight."
  }
}

variable "sns_topic_name" {
  description = "SNS topic name for CloudTrail notifications."
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
