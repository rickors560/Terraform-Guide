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

variable "zone_name" {
  description = "Domain name for the hosted zone."
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name for alias record."
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID for alias record."
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
