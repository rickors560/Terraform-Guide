# -----------------------------------------------------------------------------
# Internet Gateway Component - Variables
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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use for public subnets"
  type        = number
  default     = 3
}

variable "subnet_newbits" {
  description = "Number of additional bits to add to the VPC CIDR for subnet calculation"
  type        = number
  default     = 8
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed SSH access to public subnets"
  type        = string
  default     = "0.0.0.0/0"
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC flow logs"
  type        = number
  default     = 14
}
