###############################################################################
# Variables — 03-three-tier-app
###############################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "three-tier"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.micro"
}

variable "asg_min" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "asg_max" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4
}

variable "asg_desired" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
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
