variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 32
    error_message = "Project name must be between 1 and 32 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "uat", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, uat, sandbox."
  }
}

variable "role_name_suffix" {
  description = "Suffix for the IAM role name"
  type        = string

  validation {
    condition     = length(var.role_name_suffix) > 0
    error_message = "Role name suffix must not be empty."
  }
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:iam::[0-9]+:oidc-provider/", var.oidc_provider_arn))
    error_message = "Must be a valid OIDC provider ARN."
  }
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider (without https://)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string

  validation {
    condition     = length(var.namespace) > 0
    error_message = "Namespace must not be empty."
  }
}

variable "service_account_name" {
  description = "Kubernetes service account name"
  type        = string

  validation {
    condition     = length(var.service_account_name) > 0
    error_message = "Service account name must not be empty."
  }
}

variable "managed_policy_arns" {
  description = "List of managed IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy names to policy JSON documents"
  type        = map(string)
  default     = {}
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Must be between 3600 and 43200 seconds."
  }
}

variable "team" {
  description = "Team name for resource tagging"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center for resource tagging"
  type        = string
  default     = ""
}

variable "repository" {
  description = "Repository URL for resource tagging"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
