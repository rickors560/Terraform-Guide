# KMS Module

Production-grade AWS KMS key module with key policies, aliases, rotation, and grants.

## Features

- KMS key with configurable key policy
- Automatic key rotation with configurable period
- Key alias (primary and additional)
- Multi-region key support
- Grant configuration
- Key administrators, users, and service users
- Configurable deletion window

## Usage

```hcl
module "kms" {
  source = "../../modules/security/kms"

  project     = "myapp"
  environment = "prod"
  name        = "app-encryption"
  description = "Application data encryption key"

  enable_key_rotation     = true
  rotation_period_in_days = 365
  deletion_window_in_days = 30

  key_administrators = [
    "arn:aws:iam::123456789012:role/admin",
  ]

  key_users = [
    "arn:aws:iam::123456789012:role/myapp-prod-ecs-task",
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| name | Key name suffix | string | - | yes |
| enable_key_rotation | Enable rotation | bool | true | no |
| deletion_window_in_days | Deletion window | number | 30 | no |
| multi_region | Multi-region key | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| key_id | KMS key ID |
| key_arn | KMS key ARN |
| alias_arn | KMS alias ARN |
| alias_name | KMS alias name |
