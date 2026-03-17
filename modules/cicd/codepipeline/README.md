# CodePipeline Module

Terraform module to create AWS CodePipeline with configurable stages, artifact store, and IAM role.

## Features

- Multi-stage pipeline with flexible action configuration
- Source stage support: GitHub (CodeStar), CodeCommit, S3
- Build stage with CodeBuild integration
- Deploy stage: ECS, S3, CloudFormation
- Auto-created S3 artifact bucket with encryption and lifecycle
- IAM role with least-privilege permissions
- V1 and V2 pipeline type support
- Execution mode configuration (QUEUED, SUPERSEDED, PARALLEL)
- Consistent naming and tagging

## Usage

```hcl
module "pipeline" {
  source = "../../modules/cicd/codepipeline"

  project       = "myapp"
  environment   = "prod"
  pipeline_name = "deploy"

  stages = [
    {
      name = "Source"
      actions = [{
        name     = "GitHub"
        category = "Source"
        owner    = "AWS"
        provider = "CodeStarSourceConnection"
        output_artifacts = ["source_output"]
        configuration = {
          ConnectionArn    = "arn:aws:codestar-connections:..."
          FullRepositoryId = "org/repo"
          BranchName       = "main"
        }
      }]
    },
    {
      name = "Build"
      actions = [{
        name     = "CodeBuild"
        category = "Build"
        owner    = "AWS"
        provider = "CodeBuild"
        input_artifacts  = ["source_output"]
        output_artifacts = ["build_output"]
        configuration = {
          ProjectName = "myapp-prod-build"
        }
      }]
    }
  ]
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
| pipeline_name | Pipeline name suffix | string | - | yes |
| stages | List of stage configurations | list(object) | - | yes |
| create_artifact_bucket | Create S3 artifact bucket | bool | true | no |
| create_iam_role | Create IAM role | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| pipeline_arn | ARN of the pipeline |
| pipeline_name | Name of the pipeline |
| artifact_bucket_id | Artifact bucket ID |
| iam_role_arn | IAM role ARN |
