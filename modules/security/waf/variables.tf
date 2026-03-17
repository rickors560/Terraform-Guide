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
  description = "Short name for the WAF Web ACL."
  type        = string
  default     = "waf"
}

variable "description" {
  description = "Description of the WAF Web ACL."
  type        = string
  default     = "Managed by Terraform"
}

variable "scope" {
  description = "Scope of the WAF Web ACL (REGIONAL or CLOUDFRONT)."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "default_action" {
  description = "Default action for the Web ACL (allow or block)."
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "Default action must be allow or block."
  }
}

variable "enable_cloudwatch_metrics" {
  description = "Whether to enable CloudWatch metrics for the Web ACL."
  type        = bool
  default     = true
}

variable "sampled_requests_enabled" {
  description = "Whether to enable sampled requests."
  type        = bool
  default     = true
}

variable "enable_rate_limit_rule" {
  description = "Whether to enable the rate limiting rule."
  type        = bool
  default     = true
}

variable "rate_limit" {
  description = "Maximum number of requests per 5-minute period from a single IP."
  type        = number
  default     = 2000

  validation {
    condition     = var.rate_limit >= 100
    error_message = "Rate limit must be at least 100."
  }
}

variable "rate_limit_priority" {
  description = "Priority for the rate limit rule."
  type        = number
  default     = 1
}

variable "enable_ip_block_rule" {
  description = "Whether to enable the IP block list rule."
  type        = bool
  default     = false
}

variable "blocked_ip_addresses" {
  description = "List of IP addresses/CIDR ranges to block."
  type        = list(string)
  default     = []
}

variable "ip_block_priority" {
  description = "Priority for the IP block rule."
  type        = number
  default     = 0
}

variable "ip_address_version" {
  description = "IP address version for the IP set (IPV4 or IPV6)."
  type        = string
  default     = "IPV4"

  validation {
    condition     = contains(["IPV4", "IPV6"], var.ip_address_version)
    error_message = "IP address version must be IPV4 or IPV6."
  }
}

variable "managed_rule_groups" {
  description = "List of AWS managed rule groups to add."
  type = list(object({
    name            = string
    vendor_name     = optional(string, "AWS")
    priority        = number
    override_action = optional(string, "none")
    excluded_rules  = optional(list(string), [])
  }))
  default = [
    {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
    },
    {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 20
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 30
    },
  ]
}

variable "custom_rules" {
  description = "List of custom WAF rules."
  type = list(object({
    name     = string
    priority = number
    action   = string
    statement_json = string
    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool, true)
      sampled_requests_enabled   = optional(bool, true)
      metric_name                = string
    }), null)
  }))
  default = []
}

variable "resource_arns" {
  description = "List of resource ARNs to associate with the Web ACL (only for REGIONAL scope)."
  type        = list(string)
  default     = []
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
