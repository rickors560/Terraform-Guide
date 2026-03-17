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

variable "create_zone" {
  description = "Whether to create a new hosted zone."
  type        = bool
  default     = true
}

variable "zone_name" {
  description = "Domain name for the hosted zone (e.g., example.com)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]+[a-z0-9]$", var.zone_name))
    error_message = "Zone name must be a valid domain name."
  }
}

variable "zone_id" {
  description = "Existing hosted zone ID (used when create_zone is false)."
  type        = string
  default     = null
}

variable "private_zone" {
  description = "Whether this is a private hosted zone."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID to associate with a private hosted zone."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Whether to destroy all records in the zone when destroying the zone."
  type        = bool
  default     = false
}

variable "records" {
  description = "Map of DNS records to create."
  type = map(object({
    type    = string
    ttl     = optional(number, 300)
    records = optional(list(string), [])
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, true)
    }), null)
    set_identifier = optional(string, null)
    weighted_routing = optional(object({
      weight = number
    }), null)
    latency_routing = optional(object({
      region = string
    }), null)
    failover_routing = optional(object({
      type = string
    }), null)
    health_check_id = optional(string, null)
  }))
  default = {}
}

variable "health_checks" {
  description = "Map of Route53 health checks to create."
  type = map(object({
    type                            = optional(string, "HTTPS")
    fqdn                            = optional(string, null)
    ip_address                      = optional(string, null)
    port                            = optional(number, 443)
    resource_path                   = optional(string, "/")
    failure_threshold               = optional(number, 3)
    request_interval                = optional(number, 30)
    search_string                   = optional(string, null)
    measure_latency                 = optional(bool, false)
    regions                         = optional(list(string), null)
    enable_sni                      = optional(bool, true)
    disabled                        = optional(bool, false)
    invert_healthcheck              = optional(bool, false)
    insufficient_data_health_status = optional(string, null)
  }))
  default = {}
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
