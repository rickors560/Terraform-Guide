# -----------------------------------------------------------------------------
# EBS Component - Variables
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

variable "availability_zone" {
  description = "Availability zone for EBS volumes"
  type        = string
  default     = "ap-south-1a"
}

variable "ec2_instance_id" {
  description = "EC2 instance ID to attach volumes to (empty to skip attachment)"
  type        = string
  default     = ""
}

variable "app_data_volume_size" {
  description = "Size of the application data EBS volume in GiB"
  type        = number
  default     = 50
}

variable "app_data_volume_type" {
  description = "Type of the application data EBS volume"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "st1", "sc1"], var.app_data_volume_type)
    error_message = "Volume type must be one of: gp2, gp3, io1, io2, st1, sc1."
  }
}

variable "app_data_volume_iops" {
  description = "IOPS for the application data volume (for gp3, io1, io2)"
  type        = number
  default     = 3000
}

variable "app_data_volume_throughput" {
  description = "Throughput in MiB/s for gp3 volume"
  type        = number
  default     = 125
}

variable "logs_volume_size" {
  description = "Size of the logs EBS volume in GiB"
  type        = number
  default     = 20
}

variable "snapshot_time" {
  description = "UTC time for daily snapshot creation (HH:MM format)"
  type        = string
  default     = "03:00"
}

variable "snapshot_retain_count" {
  description = "Number of daily snapshots to retain"
  type        = number
  default     = 7
}

variable "weekly_snapshot_retain_count" {
  description = "Number of weekly snapshots to retain"
  type        = number
  default     = 4
}
