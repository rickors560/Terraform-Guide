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

variable "launch_template_id" {
  description = "ID of the launch template to use"
  type        = string
}

variable "launch_template_version" {
  description = "Version of the launch template to use"
  type        = string
  default     = "$Latest"
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 0
    error_message = "Minimum size must be >= 0."
  }
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 3

  validation {
    condition     = var.max_size >= 1
    error_message = "Maximum size must be >= 1."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_capacity >= 0
    error_message = "Desired capacity must be >= 0."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID is required."
  }
}

variable "target_group_arns" {
  description = "List of target group ARNs for the ASG"
  type        = list(string)
  default     = []
}

variable "health_check_type" {
  description = "Health check type (EC2 or ELB)"
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Health check type must be EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300

  validation {
    condition     = var.health_check_grace_period >= 0
    error_message = "Grace period must be >= 0."
  }
}

variable "default_cooldown" {
  description = "Default cooldown period in seconds"
  type        = number
  default     = 300
}

variable "force_delete" {
  description = "Allows deleting the ASG without waiting for instances to terminate"
  type        = bool
  default     = false
}

variable "termination_policies" {
  description = "List of termination policies"
  type        = list(string)
  default     = ["Default"]
}

variable "suspended_processes" {
  description = "List of processes to suspend for the ASG"
  type        = list(string)
  default     = []
}

variable "wait_for_capacity_timeout" {
  description = "Maximum duration to wait for ASG instances to be healthy"
  type        = string
  default     = "10m"
}

variable "protect_from_scale_in" {
  description = "Whether newly launched instances are protected from scale in"
  type        = bool
  default     = false
}

variable "enabled_metrics" {
  description = "List of ASG metrics to enable"
  type        = list(string)
  default = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]
}

variable "enable_instance_refresh" {
  description = "Whether to enable instance refresh"
  type        = bool
  default     = false
}

variable "instance_refresh_strategy" {
  description = "Instance refresh strategy"
  type        = string
  default     = "Rolling"
}

variable "instance_refresh_min_healthy_percentage" {
  description = "Minimum healthy percentage during instance refresh"
  type        = number
  default     = 90

  validation {
    condition     = var.instance_refresh_min_healthy_percentage >= 0 && var.instance_refresh_min_healthy_percentage <= 100
    error_message = "Must be between 0 and 100."
  }
}

variable "instance_refresh_instance_warmup" {
  description = "Instance warmup time in seconds for instance refresh"
  type        = number
  default     = 300
}

variable "enable_mixed_instances_policy" {
  description = "Whether to use a mixed instances policy"
  type        = bool
  default     = false
}

variable "mixed_instances_override" {
  description = "List of instance type overrides for mixed instances policy"
  type = list(object({
    instance_type     = string
    weighted_capacity = optional(string)
  }))
  default = []
}

variable "on_demand_base_capacity" {
  description = "Minimum number of on-demand instances"
  type        = number
  default     = 0
}

variable "on_demand_percentage_above_base_capacity" {
  description = "Percentage of on-demand instances above base capacity"
  type        = number
  default     = 100

  validation {
    condition     = var.on_demand_percentage_above_base_capacity >= 0 && var.on_demand_percentage_above_base_capacity <= 100
    error_message = "Must be between 0 and 100."
  }
}

variable "spot_allocation_strategy" {
  description = "Spot allocation strategy"
  type        = string
  default     = "capacity-optimized"

  validation {
    condition     = contains(["capacity-optimized", "capacity-optimized-prioritized", "lowest-price", "price-capacity-optimized"], var.spot_allocation_strategy)
    error_message = "Must be a valid spot allocation strategy."
  }
}

variable "enable_target_tracking_cpu" {
  description = "Enable target tracking scaling policy for CPU"
  type        = bool
  default     = false
}

variable "target_cpu_value" {
  description = "Target CPU utilization percentage"
  type        = number
  default     = 70

  validation {
    condition     = var.target_cpu_value > 0 && var.target_cpu_value <= 100
    error_message = "CPU target must be between 1 and 100."
  }
}

variable "enable_target_tracking_alb_request_count" {
  description = "Enable target tracking scaling policy for ALB request count per target"
  type        = bool
  default     = false
}

variable "target_alb_request_count_value" {
  description = "Target ALB request count per target"
  type        = number
  default     = 1000

  validation {
    condition     = var.target_alb_request_count_value > 0
    error_message = "ALB request count target must be greater than 0."
  }
}

variable "alb_target_group_arn" {
  description = "ALB target group ARN for request count tracking (required if enable_target_tracking_alb_request_count is true)"
  type        = string
  default     = null
}

variable "scaling_policy_cooldown" {
  description = "Cooldown period for scaling policies in seconds"
  type        = number
  default     = 300
}

variable "enable_warm_pool" {
  description = "Whether to enable a warm pool"
  type        = bool
  default     = false
}

variable "warm_pool_state" {
  description = "Instance state for warm pool (Stopped, Running, Hibernated)"
  type        = string
  default     = "Stopped"

  validation {
    condition     = contains(["Stopped", "Running", "Hibernated"], var.warm_pool_state)
    error_message = "Must be Stopped, Running, or Hibernated."
  }
}

variable "warm_pool_min_size" {
  description = "Minimum number of instances in the warm pool"
  type        = number
  default     = 0
}

variable "warm_pool_max_group_prepared_capacity" {
  description = "Maximum number of instances that are allowed to be in warm pool. -1 for unlimited."
  type        = number
  default     = -1
}

variable "warm_pool_reuse_on_scale_in" {
  description = "Whether instances in the warm pool can be reused on scale in"
  type        = bool
  default     = false
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
