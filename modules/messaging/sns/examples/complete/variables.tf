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

variable "fulfillment_queue_arn" {
  description = "ARN of the fulfillment SQS queue."
  type        = string
}

variable "analytics_queue_arn" {
  description = "ARN of the analytics SQS queue."
  type        = string
}

variable "webhook_url" {
  description = "HTTPS webhook endpoint URL."
  type        = string
}

variable "cross_account_ids" {
  description = "List of AWS account IDs for cross-account access."
  type        = list(string)
  default     = []
}
