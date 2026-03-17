# -----------------------------------------------------------------------------
# CloudTrail Component - Variables
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

variable "is_multi_region" {
  description = "Whether to create a multi-region trail"
  type        = bool
  default     = true
}

variable "enable_insights" {
  description = "Whether to enable CloudTrail Insights (ApiCallRateInsight, ApiErrorRateInsight)"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudTrail logs in S3 before expiration"
  type        = number
  default     = 730
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudTrail logs in CloudWatch"
  type        = number
  default     = 90
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for security alarm notifications"
  type        = list(string)
  default     = []
}
