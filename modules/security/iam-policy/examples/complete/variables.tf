variable "aws_region" {
  description = "AWS region."
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

variable "team" {
  description = "Team name."
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Cost center."
  type        = string
  default     = "infrastructure"
}
