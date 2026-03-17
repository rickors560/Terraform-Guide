# -----------------------------------------------------------------------------
# CloudWatch Component - Variables
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

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch retention period."
  }
}

variable "kms_key_arn" {
  description = "ARN of KMS key for log group encryption (empty for no encryption)"
  type        = string
  default     = null
}

variable "ec2_instance_id" {
  description = "EC2 instance ID for dimension-scoped alarms (empty for all instances)"
  type        = string
  default     = ""
}

variable "cpu_threshold_high" {
  description = "CPU utilization warning threshold percentage"
  type        = number
  default     = 75
}

variable "cpu_threshold_critical" {
  description = "CPU utilization critical threshold percentage"
  type        = number
  default     = 90
}

variable "memory_threshold" {
  description = "Memory utilization threshold percentage (requires CloudWatch Agent)"
  type        = number
  default     = 85
}

variable "disk_threshold" {
  description = "Disk utilization threshold percentage (requires CloudWatch Agent)"
  type        = number
  default     = 85
}

variable "error_rate_threshold" {
  description = "Application error count threshold per 5-minute period"
  type        = number
  default     = 50
}

variable "http_5xx_threshold" {
  description = "HTTP 5xx error count threshold per 5-minute period"
  type        = number
  default     = 20
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}
