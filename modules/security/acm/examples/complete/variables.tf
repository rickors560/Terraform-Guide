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

variable "domain_name" {
  description = "Primary domain name."
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID."
  type        = string
}

variable "subject_alternative_names" {
  description = "Subject alternative names."
  type        = list(string)
  default     = []
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
