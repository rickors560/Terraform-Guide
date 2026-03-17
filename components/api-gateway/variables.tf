###############################################################################
# API Gateway Component — Variables
###############################################################################

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "endpoint_type" {
  description = "API Gateway endpoint type: REGIONAL, EDGE, or PRIVATE"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "EDGE", "PRIVATE"], var.endpoint_type)
    error_message = "Endpoint type must be REGIONAL, EDGE, or PRIVATE."
  }
}

variable "require_api_key" {
  description = "Require API key for API access"
  type        = bool
  default     = true
}

variable "xray_tracing_enabled" {
  description = "Enable X-Ray tracing for API Gateway"
  type        = bool
  default     = false
}

variable "throttling_burst_limit" {
  description = "API Gateway throttling burst limit"
  type        = number
  default     = 50
}

variable "throttling_rate_limit" {
  description = "API Gateway throttling rate limit (requests per second)"
  type        = number
  default     = 100
}

variable "usage_plan_quota_limit" {
  description = "Monthly request quota limit"
  type        = number
  default     = 100000
}
