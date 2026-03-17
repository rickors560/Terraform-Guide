# CI/CD Modules

Terraform modules for AWS CI/CD pipelines and GitHub integration including CodePipeline, CodeBuild, and GitHub Actions OIDC authentication.

## Sub-Modules

| Module | Description |
|--------|-------------|
| [codepipeline](./codepipeline/) | AWS CodePipeline with configurable stages, artifact store, and IAM role |
| [codebuild](./codebuild/) | AWS CodeBuild projects with full environment, source, artifact, and logging configuration |
| [github-oidc](./github-oidc/) | GitHub Actions OIDC authentication with AWS for keyless access from GitHub workflows |

## How They Relate

```
github-oidc (GitHub Actions --> AWS)

codepipeline --> codebuild (pipeline triggers builds)
     |
     v
  Deploy stage (ECS, EKS, S3, Lambda, etc.)
```

- **codepipeline** orchestrates the CI/CD workflow, defining source, build, and deploy stages.
- **codebuild** provides the build environment. It is commonly used as a build or test stage within a CodePipeline.
- **github-oidc** enables GitHub Actions workflows to assume AWS IAM roles without long-lived credentials. This is an alternative to CodePipeline/CodeBuild for teams using GitHub Actions as their CI/CD platform.

## Usage Example

```hcl
# Option A: AWS-native CI/CD with CodePipeline + CodeBuild
module "build_project" {
  source = "../../modules/cicd/codebuild"

  project     = "myapp"
  environment = "prod"
  name_suffix = "build"

  source_type = "CODEPIPELINE"

  environment_config = {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"
    privileged_mode = true
  }

  team = "platform"
}

module "pipeline" {
  source = "../../modules/cicd/codepipeline"

  project     = "myapp"
  environment = "prod"
  name_suffix = "deploy"

  stages = [
    {
      name = "Source"
      actions = [{
        name     = "Source"
        category = "Source"
        provider = "CodeStarSourceConnection"
        configuration = {
          ConnectionArn    = var.codestar_connection_arn
          FullRepositoryId = "org/repo"
          BranchName       = "main"
        }
      }]
    },
    {
      name = "Build"
      actions = [{
        name     = "Build"
        category = "Build"
        provider = "CodeBuild"
        configuration = {
          ProjectName = module.build_project.project_name
        }
      }]
    }
  ]

  team = "platform"
}

# Option B: GitHub Actions with OIDC
module "github_oidc" {
  source = "../../modules/cicd/github-oidc"

  project     = "myapp"
  environment = "prod"

  github_org  = "my-org"
  github_repo = "my-repo"

  iam_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  ]

  team = "platform"
}
```
