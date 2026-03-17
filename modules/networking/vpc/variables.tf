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

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 1 && length(var.availability_zones) <= 6
    error_message = "You must specify between 1 and 6 availability zones."
  }
}

variable "public_subnet_newbits" {
  description = "Number of additional bits to add to the VPC CIDR for public subnets (used with cidrsubnet)."
  type        = number
  default     = 8

  validation {
    condition     = var.public_subnet_newbits >= 1 && var.public_subnet_newbits <= 16
    error_message = "Public subnet newbits must be between 1 and 16."
  }
}

variable "private_subnet_newbits" {
  description = "Number of additional bits to add to the VPC CIDR for private subnets (used with cidrsubnet)."
  type        = number
  default     = 8

  validation {
    condition     = var.private_subnet_newbits >= 1 && var.private_subnet_newbits <= 16
    error_message = "Private subnet newbits must be between 1 and 16."
  }
}

variable "database_subnet_newbits" {
  description = "Number of additional bits to add to the VPC CIDR for database subnets (used with cidrsubnet)."
  type        = number
  default     = 8

  validation {
    condition     = var.database_subnet_newbits >= 1 && var.database_subnet_newbits <= 16
    error_message = "Database subnet newbits must be between 1 and 16."
  }
}

variable "public_subnet_offset" {
  description = "Starting netnum offset for public subnets in cidrsubnet calculation."
  type        = number
  default     = 0
}

variable "private_subnet_offset" {
  description = "Starting netnum offset for private subnets in cidrsubnet calculation."
  type        = number
  default     = 10
}

variable "database_subnet_offset" {
  description = "Starting netnum offset for database subnets in cidrsubnet calculation."
  type        = number
  default     = 20
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateways for private subnets."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets instead of one per AZ."
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Whether to create a VPN Gateway."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs to CloudWatch."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC Flow Logs in CloudWatch."
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_log_retention_days)
    error_message = "Flow log retention days must be a valid CloudWatch Logs retention value."
  }
}

variable "flow_log_traffic_type" {
  description = "The type of traffic to capture in flow logs (ACCEPT, REJECT, or ALL)."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "Flow log traffic type must be ACCEPT, REJECT, or ALL."
  }
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "create_database_subnet_group" {
  description = "Whether to create a database subnet group for RDS."
  type        = bool
  default     = true
}

variable "create_database_subnets" {
  description = "Whether to create database subnets."
  type        = bool
  default     = true
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
