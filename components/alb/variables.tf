###############################################################################
# ALB Component — Variables
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
  description = "Subnet IDs for the ALB (at least 2 AZs)"
  type        = list(string)
}

variable "internal" {
  description = "Create an internal (private) ALB"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Idle timeout in seconds"
  type        = number
  default     = 60
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS. Leave empty for HTTP only"
  type        = string
  default     = ""
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "target_port" {
  description = "Target group port"
  type        = number
  default     = 80
}

variable "target_type" {
  description = "Target type: instance, ip, or lambda"
  type        = string
  default     = "instance"
}

variable "deregistration_delay" {
  description = "Deregistration delay in seconds"
  type        = number
  default     = 30
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP status codes for healthy response"
  type        = string
  default     = "200"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Healthy threshold count"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Unhealthy threshold count"
  type        = number
  default     = 3
}

variable "stickiness_enabled" {
  description = "Enable session stickiness"
  type        = bool
  default     = false
}

variable "stickiness_duration" {
  description = "Stickiness cookie duration in seconds"
  type        = number
  default     = 86400
}

variable "enable_access_logs" {
  description = "Enable ALB access logging to S3"
  type        = bool
  default     = true
}

variable "access_log_retention_days" {
  description = "Days to retain access logs"
  type        = number
  default     = 90
}

variable "alarm_5xx_threshold" {
  description = "Threshold for 5XX error alarm"
  type        = number
  default     = 10
}

variable "alarm_response_time_threshold" {
  description = "Threshold for response time alarm (seconds)"
  type        = number
  default     = 5
}
