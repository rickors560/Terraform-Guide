###############################################################################
# SQS Component — Variables
###############################################################################

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "queue_name" {
  description = "Name suffix for the SQS queue"
  type        = string
  default     = "main"
}

variable "fifo_queue" {
  description = "Create a FIFO queue"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication (FIFO only)"
  type        = bool
  default     = true
}

variable "delay_seconds" {
  description = "Delivery delay in seconds (0-900)"
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "Maximum message size in bytes (1024-262144)"
  type        = number
  default     = 262144
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds (60-1209600)"
  type        = number
  default     = 345600 # 4 days
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout in seconds (0-43200)"
  type        = number
  default     = 60
}

variable "receive_wait_time_seconds" {
  description = "Long poll wait time in seconds (0-20)"
  type        = number
  default     = 20
}

variable "max_receive_count" {
  description = "Number of receives before sending to DLQ"
  type        = number
  default     = 3
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption. Leave empty for SQS-managed encryption"
  type        = string
  default     = ""
}

variable "queue_depth_alarm_threshold" {
  description = "Alarm threshold for queue depth"
  type        = number
  default     = 1000
}

variable "message_age_alarm_threshold" {
  description = "Alarm threshold for oldest message age (seconds)"
  type        = number
  default     = 3600
}
