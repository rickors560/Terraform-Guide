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
  description = "VPC ID."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ALB."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the ALB."
  type        = list(string)
}

variable "ssl_certificate_arn" {
  description = "ACM certificate ARN."
  type        = string
}

variable "access_logs_bucket" {
  description = "S3 bucket for access logs."
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
