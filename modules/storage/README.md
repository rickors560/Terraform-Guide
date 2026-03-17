# Storage Modules

Terraform modules for provisioning and managing AWS storage services including object storage (S3), block storage (EBS), and file storage (EFS).

## Sub-Modules

| Module | Description |
|--------|-------------|
| [s3](./s3/) | S3 bucket with versioning, encryption, public access block, lifecycle rules, CORS, logging, object lock, and replication |
| [ebs](./ebs/) | EBS volume with configurable type, size, IOPS, throughput, and KMS encryption |
| [efs](./efs/) | EFS file system with mount targets, access points, lifecycle policies, encryption, and backup configuration |

## How They Relate

Each storage module addresses a different storage tier:

- **s3** provides object storage for static assets, backups, logs, and data lake workloads. Used by many other modules (CloudTrail logs, ALB access logs, CUR reports).
- **ebs** provides block storage volumes attached to individual EC2 instances for high-performance disk I/O.
- **efs** provides shared file storage accessible by multiple EC2 instances or ECS/EKS containers simultaneously via NFS.

## Usage Example

```hcl
module "assets_bucket" {
  source = "../../modules/storage/s3"

  project     = "myapp"
  environment = "prod"
  name_suffix = "assets"

  enable_versioning = true
  enable_encryption = true

  lifecycle_rules = [
    {
      id     = "archive-old"
      status = "Enabled"
      transition = [{ days = 90, storage_class = "GLACIER" }]
    }
  ]

  team        = "platform"
  cost_center = "CC-1234"
}

module "data_volume" {
  source = "../../modules/storage/ebs"

  project     = "myapp"
  environment = "prod"

  availability_zone = "us-east-1a"
  size              = 100
  type              = "gp3"
  iops              = 3000
  throughput        = 125
  encrypted         = true
  kms_key_id        = module.kms_key.key_arn

  team = "platform"
}

module "shared_fs" {
  source = "../../modules/storage/efs"

  project     = "myapp"
  environment = "prod"

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.efs_sg.security_group_id]

  encrypted  = true
  kms_key_id = module.kms_key.key_arn

  enable_backup = true

  team = "platform"
}
```
