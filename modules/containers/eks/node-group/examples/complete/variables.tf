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

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
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
