# EFS File System Module

Terraform module to create an AWS EFS file system with mount targets, access points, lifecycle policies, encryption, and backup configuration.

## Features

- Configurable performance mode and throughput mode
- KMS encryption at rest
- Mount targets across multiple subnets
- Access points with POSIX user and root directory settings
- Lifecycle policies (transition to IA, transition back)
- Backup policy (AWS Backup integration)
- Elastic throughput mode support

## Usage

```hcl
module "efs" {
  source = "../../modules/storage/efs"

  project     = "myapp"
  environment = "prod"

  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"
  encrypted        = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.efs.id]

  access_points = [
    {
      name = "app"
      posix_user = {
        uid = 1000
        gid = 1000
      }
      root_directory = {
        path = "/app"
        creation_info = {
          owner_uid   = 1000
          owner_gid   = 1000
          permissions = "755"
        }
      }
    }
  ]

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
| file_system_id | EFS file system ID |
| file_system_arn | EFS file system ARN |
| file_system_dns_name | EFS DNS name |
| mount_target_ids | Mount target IDs |
| access_point_ids | Access point IDs |
