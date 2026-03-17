# -----------------------------------------------------------------------------
# NACL Component - Variables
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
  description = "VPC ID for NACL creation"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs to associate with the public NACL"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks (for app tier inbound rules)"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "List of private application subnet IDs"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "List of private application subnet CIDR blocks"
  type        = list(string)
}

variable "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "List of private database subnet CIDR blocks"
  type        = list(string)
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed SSH access to public subnets"
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  description = "Application port for app tier inbound rules"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port for DB tier inbound/outbound rules"
  type        = number
  default     = 5432
}

variable "cache_port" {
  description = "Cache port for app tier outbound rules"
  type        = number
  default     = 6379
}
