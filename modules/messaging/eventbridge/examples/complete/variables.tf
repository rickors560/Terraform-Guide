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

variable "process_order_lambda_arn" {
  description = "ARN of the order processing Lambda function."
  type        = string
}

variable "order_queue_arn" {
  description = "ARN of the order SQS queue."
  type        = string
}

variable "report_lambda_arn" {
  description = "ARN of the report generation Lambda function."
  type        = string
}

variable "dlq_arn" {
  description = "ARN of the dead-letter queue for failed event deliveries."
  type        = string
}
