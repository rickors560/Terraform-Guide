# -----------------------------------------------------------------------------
# NAT Gateway Component - Variables
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "vpc_id" {
  description = "VPC ID for route table creation"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where NAT Gateways will be created"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs that will use the NAT Gateways"
  type        = list(string)
}

variable "high_availability" {
  description = "Whether to create a NAT Gateway in each AZ (true) or a single shared one (false)"
  type        = bool
  default     = true
}

variable "create_private_nat_gateway" {
  description = "Whether to create an additional private NAT Gateway (no internet, VPC-to-VPC only)"
  type        = bool
  default     = false
}

variable "private_nat_subnet_id" {
  description = "Subnet ID for the private NAT Gateway (defaults to first public subnet)"
  type        = string
  default     = ""
}

variable "nat_bandwidth_alarm_threshold" {
  description = "Threshold in bytes for NAT Gateway bandwidth alarm (per 5-minute period)"
  type        = number
  default     = 5368709120  # 5 GiB
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}
