###############################################################################
# EC2 Component — Variables
###############################################################################

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "vpc_id" {
  description = "ID of the VPC to launch the instance in"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to launch the instance in"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID to use. Leave empty for latest Amazon Linux 2023"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}

variable "data_volume_size" {
  description = "Size of the additional data EBS volume in GB. Set to 0 to skip"
  type        = number
  default     = 0
}

variable "data_volume_iops" {
  description = "IOPS for the data volume (gp3)"
  type        = number
  default     = 3000
}

variable "data_volume_throughput" {
  description = "Throughput in MiB/s for the data volume (gp3)"
  type        = number
  default     = 125
}

variable "assign_elastic_ip" {
  description = "Whether to assign an Elastic IP to the instance"
  type        = bool
  default     = true
}

variable "detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (1-minute intervals)"
  type        = bool
  default     = false
}
