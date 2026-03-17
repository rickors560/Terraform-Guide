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
  description = "Short name for the IAM policy (appended to name_prefix)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "Policy name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "description" {
  description = "Description of the IAM policy."
  type        = string
  default     = "Managed by Terraform"
}

variable "path" {
  description = "IAM path for the policy."
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/.*/$|^/$", var.path))
    error_message = "Path must start and end with a forward slash."
  }
}

variable "policy_statements" {
  description = "List of IAM policy statement objects."
  type = list(object({
    sid       = optional(string, null)
    effect    = optional(string, "Allow")
    actions   = list(string)
    resources = list(string)
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
    principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })), [])
    not_actions    = optional(list(string), [])
    not_resources  = optional(list(string), [])
    not_principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })), [])
  }))

  validation {
    condition     = length(var.policy_statements) >= 1
    error_message = "At least one policy statement must be defined."
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
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
