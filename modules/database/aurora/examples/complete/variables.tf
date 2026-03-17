variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
  default     = []
}

variable "team" {
  description = "Team name"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center"
  type        = string
  default     = ""
}

variable "repository" {
  description = "Repository URL"
  type        = string
  default     = ""
}
