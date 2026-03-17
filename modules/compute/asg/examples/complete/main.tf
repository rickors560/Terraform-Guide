provider "aws" {
  region = var.aws_region
}

module "asg" {
  source = "../../"

  project     = var.project
  environment = var.environment

  launch_template_id      = var.launch_template_id
  launch_template_version = "$Latest"

  min_size         = 2
  max_size          = 6
  desired_capacity  = 3
  subnet_ids        = var.subnet_ids
  target_group_arns = var.target_group_arns

  health_check_type         = "ELB"
  health_check_grace_period = 300

  enable_target_tracking_cpu = true
  target_cpu_value           = 70

  enable_instance_refresh                 = true
  instance_refresh_min_healthy_percentage = 90
  instance_refresh_instance_warmup        = 300

  enable_mixed_instances_policy = true
  mixed_instances_override = [
    { instance_type = "t3.medium" },
    { instance_type = "t3a.medium" },
    { instance_type = "t3.large" },
  ]
  on_demand_base_capacity                  = 1
  on_demand_percentage_above_base_capacity = 25
  spot_allocation_strategy                 = "capacity-optimized"

  enable_warm_pool         = true
  warm_pool_state          = "Stopped"
  warm_pool_min_size       = 1
  warm_pool_reuse_on_scale_in = true

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
