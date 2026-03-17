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
  description = "Short name for the ALB (appended to name_prefix)."
  type        = string
  default     = "alb"
}

variable "internal" {
  description = "Whether the ALB is internal (true) or internet-facing (false)."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "ALB requires at least 2 subnets in different availability zones."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the ALB."
  type        = list(string)
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection on the ALB."
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Time in seconds that the connection is allowed to be idle."
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "Idle timeout must be between 1 and 4000 seconds."
  }
}

variable "enable_http2" {
  description = "Whether HTTP/2 is enabled."
  type        = bool
  default     = true
}

variable "drop_invalid_header_fields" {
  description = "Whether HTTP headers with invalid header fields are removed by the ALB."
  type        = bool
  default     = true
}

variable "access_logs_enabled" {
  description = "Whether to enable ALB access logs."
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs."
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "S3 key prefix for ALB access logs."
  type        = string
  default     = ""
}

variable "enable_https_listener" {
  description = "Whether to create an HTTPS listener."
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for the HTTPS listener."
  type        = string
  default     = ""
}

variable "ssl_policy" {
  description = "SSL policy for the HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "http_default_action_type" {
  description = "Default action type for the HTTP listener (forward or redirect)."
  type        = string
  default     = "forward"

  validation {
    condition     = contains(["forward", "redirect", "fixed-response"], var.http_default_action_type)
    error_message = "HTTP default action type must be forward, redirect, or fixed-response."
  }
}

variable "https_default_action_type" {
  description = "Default action type for the HTTPS listener (forward or fixed-response)."
  type        = string
  default     = "forward"

  validation {
    condition     = contains(["forward", "fixed-response"], var.https_default_action_type)
    error_message = "HTTPS default action type must be forward or fixed-response."
  }
}

variable "fixed_response_content_type" {
  description = "Content type for fixed response (text/plain, text/html, application/json, application/javascript)."
  type        = string
  default     = "text/plain"
}

variable "fixed_response_message_body" {
  description = "Message body for fixed response."
  type        = string
  default     = "Not Found"
}

variable "fixed_response_status_code" {
  description = "Status code for fixed response."
  type        = string
  default     = "404"
}

variable "target_group_name" {
  description = "Name suffix for the default target group."
  type        = string
  default     = "default"
}

variable "target_group_port" {
  description = "Port for the default target group."
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "Protocol for the default target group."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.target_group_protocol)
    error_message = "Target group protocol must be HTTP or HTTPS."
  }
}

variable "target_type" {
  description = "Type of target (instance, ip, lambda, alb)."
  type        = string
  default     = "ip"

  validation {
    condition     = contains(["instance", "ip", "lambda", "alb"], var.target_type)
    error_message = "Target type must be instance, ip, lambda, or alb."
  }
}

variable "deregistration_delay" {
  description = "Time in seconds before deregistering a target."
  type        = number
  default     = 300
}

variable "health_check" {
  description = "Health check configuration for the target group."
  type = object({
    enabled             = optional(bool, true)
    path                = optional(string, "/")
    port                = optional(string, "traffic-port")
    protocol            = optional(string, "HTTP")
    healthy_threshold   = optional(number, 3)
    unhealthy_threshold = optional(number, 3)
    timeout             = optional(number, 5)
    interval            = optional(number, 30)
    matcher             = optional(string, "200")
  })
  default = {}
}

variable "stickiness" {
  description = "Target group stickiness configuration."
  type = object({
    enabled         = optional(bool, false)
    type            = optional(string, "lb_cookie")
    cookie_duration = optional(number, 86400)
    cookie_name     = optional(string, null)
  })
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
