# Launch Template Module

Terraform module to create an AWS EC2 Launch Template with configurable AMI, instance type, network interfaces, block device mappings, user data, IAM instance profile, and metadata options.

## Features

- AMI, instance type, and key pair configuration
- Network interfaces with security groups
- Block device mappings with encryption
- Base64 user data support
- IAM instance profile attachment
- IMDSv2 required by default
- Tag specifications for launched resources
- Versioned with automatic default version updates

## Usage

```hcl
module "launch_template" {
  source = "../../modules/compute/launch-template"

  project     = "myapp"
  environment = "prod"

  ami_id        = "ami-0abcdef1234567890"
  instance_type = "t3.medium"
  key_name      = "my-key-pair"

  security_group_ids = ["sg-0123456789abcdef0"]

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size = 50
        volume_type = "gp3"
        encrypted   = true
      }
    }
  ]

  team        = "platform"
  cost_center = "CC-1234"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| ami_id | AMI ID | string | n/a | yes |
| instance_type | Instance type | string | "t3.micro" | no |
| key_name | SSH key pair name | string | null | no |
| security_group_ids | Security group IDs | list(string) | [] | no |
| block_device_mappings | Block device config | list(object) | gp3 20GB | no |
| user_data_base64 | Base64 user data | string | null | no |
| iam_instance_profile_name | IAM profile name | string | null | no |
| metadata_http_tokens | IMDSv2 setting | string | "required" | no |

## Outputs

| Name | Description |
|------|-------------|
| launch_template_id | Launch template ID |
| launch_template_arn | Launch template ARN |
| latest_version | Latest version number |
| default_version | Default version number |
