provider "aws" {
  region = var.aws_region
}

module "cloudtrail" {
  source = "../../"

  project     = var.project
  environment = var.environment

  is_multi_region_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true
  enable_cloudwatch_logs        = true
  cloudwatch_log_group_retention = 90

  data_events = [
    {
      read_write_type = "All"
      data_resources = [
        {
          type   = "AWS::S3::Object"
          values = ["arn:aws:s3"]
        },
        {
          type   = "AWS::Lambda::Function"
          values = ["arn:aws:lambda"]
        }
      ]
    }
  ]

  insight_selectors = [
    { insight_type = "ApiCallRateInsight" },
    { insight_type = "ApiErrorRateInsight" }
  ]

  additional_tags = {
    Example = "complete"
  }
}
