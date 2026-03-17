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

variable "instance_id" {
  description = "EC2 instance ID to display on dashboard."
  type        = string
}

variable "alarm_arns" {
  description = "List of alarm ARNs to display in the alarm widget."
  type        = list(string)
  default     = []
}
