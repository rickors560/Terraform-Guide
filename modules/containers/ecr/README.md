# ECR Repository Module

Terraform module to create an AWS ECR repository with image scanning, lifecycle policies, encryption, cross-account access, and replication configuration.

## Features

- Image scanning on push
- Lifecycle policy (keep last N tagged images, expire untagged)
- Encryption (AES256 or KMS)
- Image tag mutability setting
- Cross-account access policy
- Replication configuration
- Force delete option

## Usage

```hcl
module "ecr" {
  source = "../../modules/containers/ecr"

  project                = "myapp"
  environment            = "prod"
  repository_name_suffix = "api"

  image_tag_mutability       = "IMMUTABLE"
  scan_on_push               = true
  max_tagged_image_count     = 30
  untagged_image_expiry_days = 7

  team        = "platform"
  cost_center = "CC-1234"
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
| repository_url | ECR repository URL |
| repository_arn | ECR repository ARN |
| repository_name | ECR repository name |
| registry_id | Registry ID |
