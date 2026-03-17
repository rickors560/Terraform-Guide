###############################################################################
# EventBridge Component — Variables
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

variable "event_source" {
  description = "Custom event source name (e.g., com.myapp.orders)"
  type        = string
  default     = "com.myapp.events"
}

variable "event_detail_types" {
  description = "List of event detail types to match"
  type        = list(string)
  default     = ["OrderPlaced", "OrderShipped", "UserCreated"]
}

variable "schedule_expression" {
  description = "Schedule expression for the scheduled rule (rate or cron)"
  type        = string
  default     = "rate(1 hour)"
}

variable "archive_retention_days" {
  description = "Number of days to retain events in the archive"
  type        = number
  default     = 30
}
