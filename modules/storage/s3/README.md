# S3 Bucket Module

Terraform module to create an AWS S3 bucket with versioning, encryption, public access block, lifecycle rules, CORS, logging, object lock, and replication.

## Features

- Versioning support
- Server-side encryption (SSE-S3 or SSE-KMS with Bucket Key)
- Public access block (all four settings)
- Lifecycle rules (transitions, expiration, noncurrent versions)
- CORS configuration
- Bucket policy support
- Access logging
- Object Lock with configurable retention
- Cross-region replication

## Usage

```hcl
module "s3" {
  source = "../../modules/storage/s3"

  project            = "myapp"
  environment        = "prod"
  bucket_name_suffix = "assets"

  enable_versioning = true
  sse_algorithm     = "AES256"

  lifecycle_rules = [
    {
      id = "archive-old-objects"
      transitions = [
        { days = 90, storage_class = "STANDARD_IA" },
        { days = 180, storage_class = "GLACIER" },
      ]
      noncurrent_version_expiration_days = 90
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
| bucket_id | S3 bucket ID |
| bucket_arn | S3 bucket ARN |
| bucket_domain_name | Bucket domain name |
