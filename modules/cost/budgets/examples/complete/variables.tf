variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
}

variable "project" {
  description = "Project name."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "finance_email" {
  description = "Finance team email for budget notifications."
  type        = string
}

variable "ops_email" {
  description = "Operations team email for budget notifications."
  type        = string
}

variable "sns_topic_arns" {
  description = "List of SNS topic ARNs for notifications."
  type        = list(string)
  default     = []
}
