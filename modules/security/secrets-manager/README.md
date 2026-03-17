# Secrets Manager Module

Production-grade AWS Secrets Manager module with rotation, KMS encryption, and replication.

## Features

- Secret creation with initial value (lifecycle-ignored after creation)
- KMS key integration for encryption
- Automatic rotation via Lambda
- Multi-region replication
- Resource-based policy support
- Configurable recovery window

## Usage

```hcl
module "db_secret" {
  source = "../../modules/security/secrets-manager"

  project     = "myapp"
  environment = "prod"
  name        = "database/credentials"
  description = "Database credentials"

  kms_key_id = module.kms.key_id

  secret_string = jsonencode({
    username = "admin"
    password = "initial-password"
  })

  enable_rotation     = true
  rotation_lambda_arn = module.rotation_lambda.function_arn
  rotation_days       = 30
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| name | Secret name suffix | string | - | yes |
| secret_string | Initial secret value | string | null | no |
| kms_key_id | KMS key for encryption | string | null | no |
| enable_rotation | Enable rotation | bool | false | no |
| rotation_lambda_arn | Rotation Lambda ARN | string | null | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_arn | Secret ARN |
| secret_name | Secret name |
| secret_version_id | Secret version ID |
