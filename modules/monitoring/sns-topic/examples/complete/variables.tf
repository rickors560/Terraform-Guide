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

variable "notification_email" {
  description = "Email address for notifications."
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue for subscription."
  type        = string
}
