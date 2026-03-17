# -----------------------------------------------------------------------------
# SNS Alarms Component - Variables
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

variable "critical_email_endpoints" {
  description = "Email addresses for critical alert notifications"
  type        = list(string)
  default     = []
}

variable "warning_email_endpoints" {
  description = "Email addresses for warning alert notifications"
  type        = list(string)
  default     = []
}

variable "rds_connections_threshold" {
  description = "Threshold for RDS connection count alarm"
  type        = number
  default     = 100
}

variable "alb_5xx_threshold" {
  description = "Threshold for ALB 5xx error count alarm"
  type        = number
  default     = 10
}
