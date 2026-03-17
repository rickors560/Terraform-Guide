# EC2 Component

Production-grade EC2 instance with security group, IAM role, EBS volumes, Elastic IP, and CloudWatch alarms.

## Architecture

- EC2 instance with Amazon Linux 2023 and nginx installed via user data
- Security group with SSH, HTTP, and HTTPS ingress rules
- IAM instance profile with SSM and CloudWatch agent policies
- Optional additional EBS data volume (gp3)
- Optional Elastic IP association
- CloudWatch alarms for CPU utilization and status checks
- IMDSv2 enforced for metadata security

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_instance` | EC2 instance with user data for nginx |
| `aws_security_group` | Instance security group |
| `aws_eip` | Elastic IP (optional) |
| `aws_ebs_volume` | Additional data volume (optional) |
| `aws_iam_role` | Instance IAM role with SSM and CloudWatch |
| `aws_iam_instance_profile` | Instance profile |
| `aws_cloudwatch_metric_alarm` | CPU and status check alarms |

## Prerequisites

- An existing VPC and subnet
- An existing EC2 key pair in the target region

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vpc_id` | VPC ID | `string` | — |
| `subnet_id` | Subnet ID | `string` | — |
| `instance_type` | Instance type | `string` | `t3.micro` |
| `key_pair_name` | EC2 key pair name | `string` | — |
| `ssh_allowed_cidr` | CIDR for SSH access | `string` | `0.0.0.0/0` |
| `root_volume_size` | Root volume size (GB) | `number` | `20` |
| `data_volume_size` | Data volume size (GB), 0 to skip | `number` | `0` |
| `assign_elastic_ip` | Assign EIP | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | EC2 instance ID |
| `public_ip` | Public or Elastic IP |
| `private_ip` | Private IP address |
| `security_group_id` | Security group ID |
