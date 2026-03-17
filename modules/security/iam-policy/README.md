# IAM Policy Module

Production-grade AWS IAM Policy module with structured policy statement objects.

## Features

- Custom IAM policy from structured statement objects
- Support for conditions, principals, not_actions, not_resources
- Path configuration
- Uses aws_iam_policy_document data source for proper JSON generation

## Usage

```hcl
module "s3_read_policy" {
  source = "../../modules/security/iam-policy"

  project     = "myapp"
  environment = "prod"
  name        = "s3-read"
  description = "Allow reading from application S3 buckets"

  policy_statements = [
    {
      sid       = "S3Read"
      actions   = ["s3:GetObject", "s3:ListBucket"]
      resources = [
        "arn:aws:s3:::myapp-prod-*",
        "arn:aws:s3:::myapp-prod-*/*",
      ]
    },
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| name | Policy name suffix | string | - | yes |
| policy_statements | Policy statements | list(object) | - | yes |
| description | Policy description | string | "Managed by Terraform" | no |
| path | IAM path | string | "/" | no |

## Outputs

| Name | Description |
|------|-------------|
| policy_arn | IAM policy ARN |
| policy_name | IAM policy name |
| policy_json | Generated JSON document |
