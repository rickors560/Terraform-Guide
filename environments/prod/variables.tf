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
  default     = "prod"

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
  default     = "engineering-prod"
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
  default     = "10.2.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

################################################################################
# EKS
################################################################################

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"
}

variable "eks_general_instance_types" {
  description = "Instance types for general EKS node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "eks_general_min_size" {
  description = "Minimum number of nodes in the general node group."
  type        = number
  default     = 3
}

variable "eks_general_max_size" {
  description = "Maximum number of nodes in the general node group."
  type        = number
  default     = 10
}

variable "eks_general_desired_size" {
  description = "Desired number of nodes in the general node group."
  type        = number
  default     = 3
}

variable "eks_spot_instance_types" {
  description = "Instance types for Spot EKS node group."
  type        = list(string)
  default     = ["t3.large", "t3.xlarge", "t3a.large", "t3a.xlarge"]
}

variable "eks_spot_min_size" {
  description = "Minimum number of Spot nodes."
  type        = number
  default     = 0
}

variable "eks_spot_max_size" {
  description = "Maximum number of Spot nodes."
  type        = number
  default     = 10
}

variable "eks_spot_desired_size" {
  description = "Desired number of Spot nodes."
  type        = number
  default     = 2
}

variable "eks_node_disk_size" {
  description = "Disk size in GiB for EKS worker nodes."
  type        = number
  default     = 50
}

################################################################################
# RDS
################################################################################

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.r6g.large"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for RDS in GiB."
  type        = number
  default     = 100
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for RDS autoscaling in GiB."
  type        = number
  default     = 500
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.3"
}

variable "rds_database_name" {
  description = "Name of the default database."
  type        = string
  default     = "myapp_prod"
}

variable "rds_master_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "dbadmin"
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 35
}

################################################################################
# ElastiCache Redis
################################################################################

variable "redis_node_type" {
  description = "ElastiCache Redis node type."
  type        = string
  default     = "cache.r6g.large"
}

variable "redis_engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "redis_num_node_groups" {
  description = "Number of node groups (shards) for Redis cluster mode."
  type        = number
  default     = 2
}

variable "redis_replicas_per_node_group" {
  description = "Number of replicas per node group."
  type        = number
  default     = 1
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

################################################################################
# Domain / DNS
################################################################################

variable "domain_name" {
  description = "Root domain name."
  type        = string
  default     = "myapp.example.com"
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID from global environment."
  type        = string
  default     = ""
}

################################################################################
# Monitoring
################################################################################

variable "alarm_notification_email" {
  description = "Email address for CloudWatch alarm notifications."
  type        = string
  default     = ""
}

variable "alarm_critical_email" {
  description = "Email address for critical CloudWatch alarm notifications."
  type        = string
  default     = ""
}

################################################################################
# WAF
################################################################################

variable "waf_rate_limit" {
  description = "Rate limit for WAF rule (requests per 5 minutes per IP)."
  type        = number
  default     = 2000
}

################################################################################
# Budgets
################################################################################

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD."
  type        = string
  default     = "1000"
}

variable "budget_notification_email" {
  description = "Email address for budget notifications."
  type        = string
  default     = ""
}

################################################################################
# CloudTrail
################################################################################

variable "cloudtrail_retention_days" {
  description = "Number of days to retain CloudTrail logs in S3."
  type        = number
  default     = 365
}
