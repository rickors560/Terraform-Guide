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
  description = "Short name for the NLB (appended to name_prefix)."
  type        = string
  default     = "nlb"
}

variable "internal" {
  description = "Whether the NLB is internal (true) or internet-facing (false)."
  type        = bool
  default     = true
}

variable "subnet_ids" {
  description = "List of subnet IDs for the NLB."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "NLB requires at least 1 subnet."
  }
}

variable "enable_cross_zone_load_balancing" {
  description = "Whether to enable cross-zone load balancing."
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection on the NLB."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC for target groups."
  type        = string
}

variable "listeners" {
  description = "List of listener configurations."
  type = list(object({
    port            = number
    protocol        = string
    certificate_arn = optional(string, null)
    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    alpn_policy     = optional(string, null)
    target_group_index = optional(number, 0)
  }))

  validation {
    condition     = length(var.listeners) >= 1
    error_message = "At least one listener must be defined."
  }
}

variable "target_groups" {
  description = "List of target group configurations."
  type = list(object({
    name                 = string
    port                 = number
    protocol             = string
    target_type          = optional(string, "ip")
    deregistration_delay = optional(number, 300)
    preserve_client_ip   = optional(bool, null)
    proxy_protocol_v2    = optional(bool, false)
    health_check = optional(object({
      enabled             = optional(bool, true)
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "TCP")
      path                = optional(string, null)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
      interval            = optional(number, 30)
    }), {})
  }))

  validation {
    condition     = length(var.target_groups) >= 1
    error_message = "At least one target group must be defined."
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
