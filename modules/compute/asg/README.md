# Auto Scaling Group Module

Terraform module to create an AWS Auto Scaling Group with launch template reference, scaling policies, instance refresh, mixed instances policy, and warm pool support.

## Features

- Launch template integration with version control
- Min/max/desired capacity configuration
- Health check (EC2/ELB) with configurable grace period
- Target tracking scaling policies (CPU, ALB request count)
- Instance refresh with rolling strategy
- Mixed instances policy (on-demand + spot)
- Warm pool with configurable state and reuse policy
- Configurable termination policies and suspended processes

## Usage

```hcl
module "asg" {
  source = "../../modules/compute/asg"

  project     = "myapp"
  environment = "prod"

  launch_template_id      = module.launch_template.launch_template_id
  launch_template_version = "$Latest"

  min_size         = 2
  max_size          = 10
  desired_capacity  = 3
  subnet_ids        = ["subnet-xxx", "subnet-yyy"]
  target_group_arns = [aws_lb_target_group.main.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  enable_target_tracking_cpu = true
  target_cpu_value           = 70

  enable_instance_refresh = true

  enable_mixed_instances_policy = true
  mixed_instances_override = [
    { instance_type = "t3.medium" },
    { instance_type = "t3a.medium" },
  ]
  on_demand_percentage_above_base_capacity = 25

  team        = "platform"
  cost_center = "CC-1234"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Outputs

| Name | Description |
|------|-------------|
| asg_id | ASG ID |
| asg_arn | ASG ARN |
| asg_name | ASG name |
