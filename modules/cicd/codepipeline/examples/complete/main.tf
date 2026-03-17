provider "aws" {
  region = var.aws_region
}

module "pipeline" {
  source = "../../"

  project       = var.project
  environment   = var.environment
  pipeline_name = "app-deploy"
  pipeline_type = "V2"

  stages = [
    {
      name = "Source"
      actions = [
        {
          name             = "GitHub-Source"
          category         = "Source"
          owner            = "AWS"
          provider         = "CodeStarSourceConnection"
          version          = "1"
          output_artifacts = ["source_output"]
          configuration = {
            ConnectionArn    = var.codestar_connection_arn
            FullRepositoryId = var.github_repository
            BranchName       = var.branch_name
          }
        }
      ]
    },
    {
      name = "Build"
      actions = [
        {
          name             = "Build"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          version          = "1"
          input_artifacts  = ["source_output"]
          output_artifacts = ["build_output"]
          configuration = {
            ProjectName = var.codebuild_project_name
          }
        }
      ]
    },
    {
      name = "Deploy"
      actions = [
        {
          name            = "Deploy-to-ECS"
          category        = "Deploy"
          owner           = "AWS"
          provider        = "ECS"
          version         = "1"
          input_artifacts = ["build_output"]
          configuration = {
            ClusterName = var.ecs_cluster_name
            ServiceName = var.ecs_service_name
          }
        }
      ]
    }
  ]

  additional_tags = {
    Example = "complete"
  }
}
