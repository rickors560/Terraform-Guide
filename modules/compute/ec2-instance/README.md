# EC2 Instance Module

Terraform module to create and manage an AWS EC2 instance with configurable root EBS volume, IAM instance profile, detailed monitoring, and optional Elastic IP association.

## Features

- Configurable AMI, instance type, subnet, and security groups
- Root EBS volume with encryption (KMS support)
- User data support (raw or base64)
- IAM instance profile attachment
- Detailed CloudWatch monitoring toggle
- Elastic IP association option
- IMDSv2 enforcement by default
- Termination protection option

## Usage

```hcl
module "ec2_instance" {
  source = "../../modules/compute/ec2-instance"

  project     = "myapp"
  environment = "prod"

  ami_id             = "ami-0abcdef1234567890"
  instance_type      = "t3.medium"
  subnet_id          = "subnet-0123456789abcdef0"
  security_group_ids = ["sg-0123456789abcdef0"]
  key_name           = "my-key-pair"

  root_volume_type      = "gp3"
  root_volume_size      = 50
  root_volume_encrypted = true

  enable_detailed_monitoring = true
  associate_eip              = true

  team        = "platform"
  cost_center = "CC-1234"
  repository  = "https://github.com/example/terraform-guide"
}
```

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.9.0 |
| aws       | ~> 5.0   |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| ami_id | AMI ID | string | n/a | yes |
| instance_type | Instance type | string | "t3.micro" | no |
| subnet_id | Subnet ID | string | n/a | yes |
| security_group_ids | Security group IDs | list(string) | [] | no |
| key_name | SSH key pair name | string | null | no |
| root_volume_type | EBS volume type | string | "gp3" | no |
| root_volume_size | EBS volume size (GiB) | number | 20 | no |
| root_volume_encrypted | Encrypt root volume | bool | true | no |
| root_volume_kms_key_id | KMS key ARN for encryption | string | null | no |
| user_data | User data script | string | null | no |
| iam_instance_profile_name | IAM instance profile | string | null | no |
| enable_detailed_monitoring | Enable detailed monitoring | bool | false | no |
| associate_eip | Associate Elastic IP | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 instance ID |
| instance_arn | EC2 instance ARN |
| private_ip | Private IP address |
| public_ip | Public IP address |
| eip_public_ip | Elastic IP address |
