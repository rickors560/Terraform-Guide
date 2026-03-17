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

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL (without https://)"
  type        = string
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
