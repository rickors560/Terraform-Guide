###############################################################################
# SNS Component — Variables
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

variable "topic_name" {
  description = "Name suffix for the SNS topic"
  type        = string
  default     = "notifications"
}

variable "fifo_topic" {
  description = "Create a FIFO topic"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption. Leave empty for AWS-managed SNS key"
  type        = string
  default     = ""
}

variable "email_subscribers" {
  description = "List of email addresses to subscribe"
  type        = list(string)
  default     = []
}

variable "sqs_subscriber_arns" {
  description = "List of SQS queue ARNs to subscribe"
  type        = list(string)
  default     = []
}

variable "lambda_subscriber_arns" {
  description = "List of Lambda function ARNs to subscribe"
  type        = list(string)
  default     = []
}

variable "raw_message_delivery" {
  description = "Enable raw message delivery for SQS subscriptions"
  type        = bool
  default     = true
}

variable "filter_policy" {
  description = "JSON filter policy for SQS subscriptions. Leave empty to receive all messages"
  type        = string
  default     = ""
}
