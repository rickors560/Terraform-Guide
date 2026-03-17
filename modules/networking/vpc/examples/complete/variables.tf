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

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones."
  type        = list(string)
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

variable "repository" {
  description = "Repository URL for tagging."
  type        = string
  default     = ""
}
