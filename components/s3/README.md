# S3 Component

Production-grade S3 bucket with versioning, encryption, lifecycle rules, public access block, bucket policy, and CORS.

## Features

- **Versioning** enabled by default with non-current version lifecycle management
- **Encryption** with SSE-S3 (AES256) or SSE-KMS
- **Public access block** fully enabled (all four settings)
- **Bucket policy** enforcing TLS 1.2+ and same-account access only
- **Lifecycle rules** for storage class transitions and cleanup
- **CORS** configuration (optional)
- **Access logging** to a separate bucket (optional)

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_s3_bucket` | The S3 bucket |
| `aws_s3_bucket_versioning` | Versioning configuration |
| `aws_s3_bucket_server_side_encryption_configuration` | Encryption settings |
| `aws_s3_bucket_public_access_block` | Block all public access |
| `aws_s3_bucket_ownership_controls` | BucketOwnerEnforced |
| `aws_s3_bucket_lifecycle_configuration` | Lifecycle rules |
| `aws_s3_bucket_policy` | TLS and account enforcement |
| `aws_s3_bucket_cors_configuration` | CORS rules (optional) |
| `aws_s3_bucket_logging` | Access logging (optional) |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `bucket_suffix` | Suffix for bucket name | `string` | `data` |
| `versioning_enabled` | Enable versioning | `bool` | `true` |
| `kms_key_arn` | KMS key ARN (empty for AES256) | `string` | `""` |
| `cors_allowed_origins` | CORS origins | `list(string)` | `[]` |
| `force_destroy` | Allow destroy with objects | `bool` | `false` |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | Bucket name |
| `bucket_arn` | Bucket ARN |
| `bucket_domain_name` | Bucket domain name |
| `bucket_regional_domain_name` | Regional domain name |
