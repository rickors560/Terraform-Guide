###############################################################################
# Variables — 07-multi-region
###############################################################################

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "secondary_region" {
  description = "Secondary (DR) AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "multi-region"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "primary_vpc_cidr" {
  description = "VPC CIDR block for primary region"
  type        = string
  default     = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  description = "VPC CIDR block for secondary region"
  type        = string
  default     = "10.1.0.0/16"
}

variable "domain_name" {
  description = "Root domain name (must have a Route53 hosted zone)"
  type        = string
}

variable "site_domain" {
  description = "Full domain for the application"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "appadmin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}
