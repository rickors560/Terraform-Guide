# ECR Component

Production-grade ECR repository with lifecycle policies, image scanning, encryption, and cross-account access.

## Features

- Immutable image tags by default
- Image scanning on push (basic or enhanced/continuous)
- AES256 or KMS encryption
- Lifecycle policies for tagged, dev, and untagged images
- Cross-account pull access
- Optional pull-through cache for ECR Public

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply

# Login and push
$(terraform output -raw login_command)
docker tag myapp:latest $(terraform output -raw repository_url):v1.0.0
docker push $(terraform output -raw repository_url):v1.0.0
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `repository_name` | Repository name | `string` | `app` |
| `image_tag_mutability` | MUTABLE or IMMUTABLE | `string` | `IMMUTABLE` |
| `scan_on_push` | Scan on push | `bool` | `true` |
| `cross_account_pull_ids` | Cross-account IDs | `list(string)` | `[]` |

## Outputs

| Name | Description |
|------|-------------|
| `repository_url` | Full repository URL |
| `repository_arn` | Repository ARN |
| `login_command` | Docker login command |
