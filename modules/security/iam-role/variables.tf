variable "project" {
  description = "Project name used for resource naming and tagging."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "uat", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, uat, sandbox."
  }
}

variable "name" {
  description = "Short name for the IAM role (appended to name_prefix)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "Role name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "description" {
  description = "Description of the IAM role."
  type        = string
  default     = "Managed by Terraform"
}

variable "path" {
  description = "IAM path for the role."
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/.*/$|^/$", var.path))
    error_message = "Path must start and end with a forward slash."
  }
}

variable "max_session_duration" {
  description = "Maximum session duration (in seconds) for the role."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Max session duration must be between 3600 and 43200 seconds."
  }
}

variable "permissions_boundary_arn" {
  description = "ARN of the IAM policy to use as a permissions boundary."
  type        = string
  default     = null
}

variable "trusted_services" {
  description = "List of AWS service principals that can assume this role."
  type        = list(string)
  default     = []
}

variable "trusted_account_ids" {
  description = "List of AWS account IDs that can assume this role."
  type        = list(string)
  default     = []
}

variable "trusted_oidc_providers" {
  description = "List of OIDC provider configurations for trust relationships."
  type = list(object({
    provider_arn = string
    client_ids   = list(string)
    condition    = optional(string, "StringEquals")
    variable     = string
    values       = list(string)
  }))
  default = []
}

variable "custom_assume_role_policy" {
  description = "Custom assume role policy JSON. If set, overrides service/account/OIDC trust."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "List of managed IAM policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy names to policy JSON documents."
  type        = map(string)
  default     = {}
}

variable "create_instance_profile" {
  description = "Whether to create an instance profile for this role."
  type        = bool
  default     = false
}

variable "force_detach_policies" {
  description = "Whether to force detaching policies before destroying the role."
  type        = bool
  default     = true
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
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
