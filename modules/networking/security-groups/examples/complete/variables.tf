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

variable "vpc_id" {
  description = "VPC ID where security groups will be created."
  type        = string
}

variable "team" {
  description = "Team name for tagging."
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Cost center for tagging."
  type        = string
  default     = "infrastructure"
}
