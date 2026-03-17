variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID for the instance"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "associate_eip" {
  description = "Whether to associate an Elastic IP"
  type        = bool
  default     = false
}

variable "team" {
  description = "Team name for tagging"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center for tagging"
  type        = string
  default     = ""
}

variable "repository" {
  description = "Repository URL for tagging"
  type        = string
  default     = ""
}
