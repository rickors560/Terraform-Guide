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
  description = "Email address for alarm notifications."
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID to monitor."
  type        = string
}
