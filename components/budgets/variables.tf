# -----------------------------------------------------------------------------
# Budgets Component - Variables
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

variable "monthly_budget_amount" {
  description = "Monthly cost budget amount in USD"
  type        = string
  default     = "1000"
}

variable "ec2_budget_amount" {
  description = "Monthly EC2 cost budget amount in USD"
  type        = string
  default     = "500"
}

variable "rds_budget_amount" {
  description = "Monthly RDS cost budget amount in USD"
  type        = string
  default     = "300"
}

variable "data_transfer_budget_amount" {
  description = "Monthly data transfer cost budget amount in USD"
  type        = string
  default     = "100"
}

variable "budget_notification_emails" {
  description = "Email addresses for budget notifications"
  type        = list(string)
  default     = []
}

variable "budget_sns_topic_arns" {
  description = "SNS topic ARNs for budget notifications"
  type        = list(string)
  default     = []
}
