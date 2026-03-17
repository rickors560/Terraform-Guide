# EBS Volume Module

Terraform module to create an AWS EBS volume with configurable type, size, IOPS, throughput, and KMS encryption.

## Features

- Configurable volume type (gp3, io2, etc.)
- Size, IOPS, and throughput settings
- KMS encryption support
- Snapshot ID for volume creation
- Multi-attach option (io1/io2)
- Final snapshot option

## Usage

```hcl
module "ebs" {
  source = "../../modules/storage/ebs"

  project             = "myapp"
  environment         = "prod"
  volume_name_suffix  = "data"

  availability_zone = "us-east-1a"
  type              = "gp3"
  size              = 100
  encrypted         = true

  team = "platform"
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
| volume_id | EBS volume ID |
| volume_arn | EBS volume ARN |
| size | Volume size |
