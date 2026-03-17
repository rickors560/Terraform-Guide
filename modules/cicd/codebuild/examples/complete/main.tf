provider "aws" {
  region = var.aws_region
}

module "codebuild" {
  source = "../../"

  project            = var.project
  environment        = var.environment
  build_project_name = "app-build"
  description        = "Build and test application container image"

  build_timeout  = 30
  compute_type   = "BUILD_GENERAL1_MEDIUM"
  image          = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
  privileged_mode = true

  source_type = "CODEPIPELINE"

  buildspec = <<-BUILDSPEC
    version: 0.2
    phases:
      pre_build:
        commands:
          - echo Logging in to Amazon ECR...
          - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $REPOSITORY_URI
      build:
        commands:
          - echo Building Docker image...
          - docker build -t $REPOSITORY_URI:$CODEBUILD_RESOLVED_SOURCE_VERSION .
          - docker tag $REPOSITORY_URI:$CODEBUILD_RESOLVED_SOURCE_VERSION $REPOSITORY_URI:latest
      post_build:
        commands:
          - echo Pushing Docker image...
          - docker push $REPOSITORY_URI:$CODEBUILD_RESOLVED_SOURCE_VERSION
          - docker push $REPOSITORY_URI:latest
          - printf '[{"name":"app","imageUri":"%s"}]' $REPOSITORY_URI:$CODEBUILD_RESOLVED_SOURCE_VERSION > imagedefinitions.json
    artifacts:
      files:
        - imagedefinitions.json
  BUILDSPEC

  environment_variables = {
    REPOSITORY_URI    = var.ecr_repository_uri
    AWS_DEFAULT_REGION = var.aws_region
  }

  environment_variables_ssm = {
    NPM_TOKEN = "/myapp/npm-token"
  }

  cache_type  = "LOCAL"
  cache_modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]

  additional_tags = {
    Example = "complete"
  }
}
