################################################################################
# General
################################################################################

variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
  default     = "myapp"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment."
  type        = string
  default     = "ap-south-1"
}

variable "team" {
  description = "Team name for resource tagging."
  type        = string
  default     = "platform"
}

variable "cost_center" {
  description = "Cost center for resource tagging."
  type        = string
  default     = "engineering-staging"
}

variable "repository" {
  description = "Repository URL for resource tagging."
  type        = string
  default     = "https://github.com/myorg/terraform-guide"
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# VPC
################################################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

################################################################################
# EKS
################################################################################

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in the EKS node group."
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in the EKS node group."
  type        = number
  default     = 4
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in the EKS node group."
  type        = number
  default     = 2
}

variable "eks_node_disk_size" {
  description = "Disk size in GiB for EKS worker nodes."
  type        = number
  default     = 30
}

################################################################################
# RDS
################################################################################

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.small"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS in GiB."
  type        = number
  default     = 50
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.3"
}

variable "rds_database_name" {
  description = "Name of the default database."
  type        = string
  default     = "myapp_staging"
}

variable "rds_master_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "dbadmin"
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 14
}

################################################################################
# ElastiCache Redis
################################################################################

variable "redis_node_type" {
  description = "ElastiCache Redis node type."
  type        = string
  default     = "cache.t3.small"
}

variable "redis_engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "redis_num_cache_clusters" {
  description = "Number of cache clusters in the Redis replication group."
  type        = number
  default     = 2
}

################################################################################
# S3
################################################################################

variable "s3_force_destroy" {
  description = "Allow force destroy of S3 buckets."
  type        = bool
  default     = false
}

################################################################################
# ECR
################################################################################

variable "ecr_repositories" {
  description = "List of ECR repository names to create."
  type        = list(string)
  default     = ["myapp-api", "myapp-web", "myapp-worker"]
}

variable "ecr_image_tag_mutability" {
  description = "Tag mutability setting for ECR repositories."
  type        = string
  default     = "IMMUTABLE"
}

################################################################################
# Domain / DNS
################################################################################

variable "domain_name" {
  description = "Root domain name."
  type        = string
  default     = "myapp.example.com"
}

################################################################################
# Monitoring
################################################################################

variable "alarm_notification_email" {
  description = "Email address for CloudWatch alarm notifications."
  type        = string
  default     = ""
}
