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

variable "create_oidc_provider" {
  description = "Whether to create the GitHub OIDC identity provider. Set to false if it already exists in the account."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "ARN of the existing GitHub OIDC provider. Used when create_oidc_provider is false."
  type        = string
  default     = null
}

variable "thumbprint_list" {
  description = "List of server certificate thumbprints for the OIDC provider. GitHub's thumbprint is included by default."
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

variable "github_repositories" {
  description = "List of GitHub repositories and their branch/environment access configurations."
  type = list(object({
    owner              = string
    name               = string
    branches           = optional(list(string), ["main"])
    environments       = optional(list(string), [])
    tags               = optional(list(string), [])
    allow_pull_requests = optional(bool, false)
  }))

  validation {
    condition     = length(var.github_repositories) > 0
    error_message = "At least one GitHub repository must be configured."
  }
}

variable "role_name_suffix" {
  description = "Suffix for the IAM role name. Full name will be {project}-{environment}-github-{suffix}."
  type        = string
  default     = "actions"
}

variable "role_max_session_duration" {
  description = "Maximum session duration in seconds for the IAM role (3600-43200)."
  type        = number
  default     = 3600

  validation {
    condition     = var.role_max_session_duration >= 3600 && var.role_max_session_duration <= 43200
    error_message = "Role max session duration must be between 3600 and 43200 seconds."
  }
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the GitHub Actions role."
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy names to policy JSON documents to attach to the role."
  type        = map(string)
  default     = {}
}

variable "permissions_boundary_arn" {
  description = "ARN of the permissions boundary policy to attach to the role."
  type        = string
  default     = null
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
