variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
  default     = "myapp"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase alphanumeric characters and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment."
  type        = string
  default     = "ap-south-1"
}

variable "domain_name" {
  description = "Root domain name for Route53 hosted zone."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]+[a-z0-9]$", var.domain_name))
    error_message = "Domain name must be a valid DNS name."
  }
}

variable "team" {
  description = "Team name for resource tagging."
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Cost center for resource tagging."
  type        = string
  default     = "infrastructure"
}

variable "repository" {
  description = "Repository URL for resource tagging."
  type        = string
  default     = "https://github.com/myorg/terraform-guide"
}

variable "admin_max_session_duration" {
  description = "Maximum session duration for admin role in seconds."
  type        = number
  default     = 3600
}

variable "developer_max_session_duration" {
  description = "Maximum session duration for developer role in seconds."
  type        = number
  default     = 3600
}

variable "readonly_max_session_duration" {
  description = "Maximum session duration for readonly role in seconds."
  type        = number
  default     = 3600
}

variable "trusted_account_ids" {
  description = "List of AWS account IDs allowed to assume roles."
  type        = list(string)
  default     = []
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
