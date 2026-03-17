###############################################################################
# NLB Component — Variables
###############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the NLB (at least 2 AZs)"
  type        = list(string)
}

variable "internal" {
  description = "Create an internal NLB"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "listener_port" {
  description = "TCP listener port"
  type        = number
  default     = 80
}

variable "target_port" {
  description = "Target port"
  type        = number
  default     = 80
}

variable "target_type" {
  description = "Target type: instance, ip, or alb"
  type        = string
  default     = "instance"
}

variable "deregistration_delay" {
  description = "Deregistration delay in seconds"
  type        = number
  default     = 300
}

variable "connection_termination" {
  description = "Enable connection termination on deregistration"
  type        = bool
  default     = false
}

variable "preserve_client_ip" {
  description = "Preserve client IP address"
  type        = bool
  default     = true
}

variable "proxy_protocol_v2" {
  description = "Enable Proxy Protocol v2"
  type        = bool
  default     = false
}

variable "stickiness_enabled" {
  description = "Enable source IP stickiness"
  type        = bool
  default     = false
}

variable "health_check_protocol" {
  description = "Health check protocol: TCP, HTTP, or HTTPS"
  type        = string
  default     = "TCP"
}

variable "health_check_port" {
  description = "Health check port (traffic-port or specific port)"
  type        = string
  default     = "traffic-port"
}

variable "health_check_path" {
  description = "Health check path (HTTP/HTTPS only)"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_healthy_threshold" {
  description = "Healthy threshold"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Unhealthy threshold"
  type        = number
  default     = 3
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for TLS listener. Leave empty to skip"
  type        = string
  default     = ""
}

variable "tls_listener_port" {
  description = "TLS listener port"
  type        = number
  default     = 443
}

variable "ssl_policy" {
  description = "SSL policy for TLS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "alpn_policy" {
  description = "ALPN policy for TLS listener"
  type        = string
  default     = "HTTP2Preferred"
}

variable "alarm_active_flows_threshold" {
  description = "Threshold for active flows alarm"
  type        = number
  default     = 10000
}
