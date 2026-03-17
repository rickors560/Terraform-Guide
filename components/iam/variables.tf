# -----------------------------------------------------------------------------
# IAM Component - Variables
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.project_name))
    error_message = "Project name must be 3-30 characters, lowercase alphanumeric with hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "iam_users" {
  description = "Map of IAM users to create with their department and group assignment"
  type = map(object({
    department = string
    group      = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for user in values(var.iam_users) :
      contains(["admin", "developer", "readonly"], user.group)
    ])
    error_message = "Each user's group must be one of: admin, developer, readonly."
  }
}

variable "trusted_account_ids" {
  description = "List of AWS account IDs trusted for cross-account role assumption"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for id in var.trusted_account_ids :
      can(regex("^[0-9]{12}$", id))
    ])
    error_message = "Each account ID must be a 12-digit number."
  }
}

variable "enable_github_oidc" {
  description = "Whether to create an OIDC provider and role for GitHub Actions"
  type        = bool
  default     = false
}

variable "github_repositories" {
  description = "List of GitHub repositories allowed to assume the OIDC role (format: org/repo)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for repo in var.github_repositories :
      can(regex("^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$", repo))
    ])
    error_message = "Each repository must be in the format 'org/repo'."
  }
}
