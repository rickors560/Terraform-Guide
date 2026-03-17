variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string

  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 32
    error_message = "Project name must be between 1 and 32 characters."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "uat", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, uat, sandbox."
  }
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string

  validation {
    condition     = length(var.service_name) > 0
    error_message = "Service name must not be empty."
  }
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Must be 256, 512, 1024, 2048, or 4096."
  }
}

variable "task_memory" {
  description = "Memory (MiB) for the task"
  type        = number
  default     = 512

  validation {
    condition     = var.task_memory >= 512
    error_message = "Memory must be at least 512 MiB."
  }
}

variable "container_definitions" {
  description = "JSON encoded container definitions"
  type        = string
}

variable "task_execution_role_arn" {
  description = "ARN of the task execution IAM role. If not provided, one will be created."
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "ARN of the task IAM role"
  type        = string
  default     = null
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "Desired count must be >= 0."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs for the service network configuration"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID is required."
  }
}

variable "security_group_ids" {
  description = "Security group IDs for the service"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI"
  type        = bool
  default     = false
}

variable "enable_load_balancer" {
  description = "Whether to attach a load balancer to the service"
  type        = bool
  default     = false
}

variable "lb_target_group_arn" {
  description = "ARN of the load balancer target group"
  type        = string
  default     = null
}

variable "lb_container_name" {
  description = "Container name for the load balancer"
  type        = string
  default     = null
}

variable "lb_container_port" {
  description = "Container port for the load balancer"
  type        = number
  default     = 80
}

variable "health_check_grace_period_seconds" {
  description = "Health check grace period for the service"
  type        = number
  default     = 60
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployment"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Maximum percent during deployment"
  type        = number
  default     = 200
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for the service"
  type        = bool
  default     = false
}

variable "enable_autoscaling" {
  description = "Enable auto scaling for the service"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks for auto scaling"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks for auto scaling"
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 70
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization percentage for auto scaling"
  type        = number
  default     = 70
}

variable "enable_service_discovery" {
  description = "Whether to enable service discovery"
  type        = bool
  default     = false
}

variable "service_discovery_namespace_id" {
  description = "Service discovery private DNS namespace ID"
  type        = string
  default     = null
}

variable "service_discovery_dns_ttl" {
  description = "TTL for service discovery DNS records"
  type        = number
  default     = 10
}

variable "platform_version" {
  description = "Fargate platform version"
  type        = string
  default     = "LATEST"
}

variable "enable_circuit_breaker" {
  description = "Enable deployment circuit breaker"
  type        = bool
  default     = true
}

variable "circuit_breaker_rollback" {
  description = "Enable rollback on deployment circuit breaker"
  type        = bool
  default     = true
}

variable "volumes" {
  description = "List of volume definitions for the task"
  type = list(object({
    name = string
    efs_volume_configuration = optional(object({
      file_system_id     = string
      root_directory     = optional(string, "/")
      transit_encryption = optional(string, "ENABLED")
    }))
  }))
  default = []
}

variable "team" {
  description = "Team name for resource tagging"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center for resource tagging"
  type        = string
  default     = ""
}

variable "repository" {
  description = "Repository URL for resource tagging"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
