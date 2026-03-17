# Compute Modules

Terraform modules for provisioning and managing AWS compute resources including EC2 instances, Auto Scaling Groups, Launch Templates, and Lambda functions.

## Sub-Modules

| Module | Description |
|--------|-------------|
| [ec2-instance](./ec2-instance/) | EC2 instances with configurable EBS volumes, IAM instance profiles, detailed monitoring, and optional Elastic IPs |
| [launch-template](./launch-template/) | EC2 Launch Templates with AMI, instance type, network interfaces, block devices, user data, and metadata options |
| [asg](./asg/) | Auto Scaling Groups with launch template reference, scaling policies, instance refresh, mixed instances, and warm pool support |
| [lambda](./lambda/) | Lambda functions with IAM role, CloudWatch log group, VPC configuration, dead letter queue, layers, and event source mappings |

## How They Relate

```
launch-template --> asg (ASG references a launch template)

ec2-instance        (standalone instances for bastion hosts, etc.)

lambda              (serverless compute, independent of EC2 resources)
```

- **launch-template** defines the instance configuration (AMI, instance type, user data) and is referenced by **asg** to launch identical instances at scale.
- **asg** manages the fleet of EC2 instances, handling scaling, health checks, and rolling updates.
- **ec2-instance** is used for standalone instances such as bastion hosts or one-off workloads that do not require auto scaling.
- **lambda** provides serverless compute for event-driven workloads, independent of the EC2 stack.

## Usage Example

```hcl
module "launch_template" {
  source = "../../modules/compute/launch-template"

  project     = "myapp"
  environment = "prod"
  name_suffix = "web"

  ami_id        = "ami-0abcdef1234567890"
  instance_type = "t3.medium"

  iam_instance_profile_arn = module.app_role.instance_profile_arn

  user_data = base64encode(file("${path.module}/scripts/init.sh"))

  team = "platform"
}

module "asg" {
  source = "../../modules/compute/asg"

  project     = "myapp"
  environment = "prod"
  name_suffix = "web"

  launch_template_id      = module.launch_template.launch_template_id
  launch_template_version = module.launch_template.latest_version

  vpc_zone_identifier = module.vpc.private_subnet_ids
  target_group_arns   = [module.alb.target_group_arn]

  min_size     = 2
  max_size     = 10
  desired_size = 3

  team = "platform"
}

module "api_lambda" {
  source = "../../modules/compute/lambda"

  project       = "myapp"
  environment   = "prod"
  function_name = "api-handler"

  runtime  = "nodejs20.x"
  handler  = "index.handler"
  filename = "lambda.zip"

  memory_size = 256
  timeout     = 30

  team = "platform"
}
```
