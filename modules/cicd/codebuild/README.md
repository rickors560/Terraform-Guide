# CodeBuild Module

Terraform module to create and manage AWS CodeBuild projects with full environment, source, artifact, and logging configuration.

## Features

- Flexible environment configuration (compute, image, type, privileged mode)
- Multiple source providers (GitHub, CodeCommit, S3, CodePipeline)
- Inline or file-based buildspec
- S3 and CodePipeline artifact support
- VPC configuration for private resource access
- CloudWatch Logs and S3 logging
- Environment variables from plaintext, SSM Parameter Store, and Secrets Manager
- Cache configuration (S3 or local)
- IAM role with least-privilege permissions
- Consistent naming and tagging

## Usage

```hcl
module "codebuild" {
  source = "../../modules/cicd/codebuild"

  project            = "myapp"
  environment        = "prod"
  build_project_name = "build"

  compute_type     = "BUILD_GENERAL1_MEDIUM"
  image            = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
  privileged_mode  = true

  source_type = "CODEPIPELINE"

  environment_variables = {
    APP_ENV = "production"
  }

  environment_variables_ssm = {
    DB_PASSWORD = "/myapp/prod/db-password"
  }

  cache_type  = "LOCAL"
  cache_modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| build_project_name | Build project name suffix | string | - | yes |
| compute_type | Compute type | string | BUILD_GENERAL1_SMALL | no |
| image | Docker image | string | amazonlinux2-x86_64-standard:5.0 | no |
| source_type | Source provider type | string | CODEPIPELINE | no |
| buildspec | Inline buildspec or file path | string | null | no |
| environment_variables | Plaintext env vars | map(string) | {} | no |
| environment_variables_ssm | SSM env vars | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| project_arn | ARN of the CodeBuild project |
| project_name | Name of the CodeBuild project |
| iam_role_arn | IAM role ARN |
