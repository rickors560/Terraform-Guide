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
  description = "Short name for the security group (appended to name_prefix)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Security group name must contain only lowercase alphanumeric characters and hyphens."
  }
}

variable "description" {
  description = "Description of the security group."
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "ID of the VPC where the security group will be created."
  type        = string
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group."
  type = list(object({
    from_port         = number
    to_port           = number
    protocol          = string
    cidr_blocks       = optional(list(string), [])
    ipv6_cidr_blocks  = optional(list(string), [])
    security_group_id = optional(string, null)
    self              = optional(bool, false)
    description       = optional(string, "")
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules for the security group."
  type = list(object({
    from_port         = number
    to_port           = number
    protocol          = string
    cidr_blocks       = optional(list(string), [])
    ipv6_cidr_blocks  = optional(list(string), [])
    security_group_id = optional(string, null)
    self              = optional(bool, false)
    description       = optional(string, "")
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

variable "revoke_rules_on_delete" {
  description = "Whether to revoke all security group rules before deleting the group."
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
