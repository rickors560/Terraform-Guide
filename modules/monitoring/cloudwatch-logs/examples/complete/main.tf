provider "aws" {
  region = var.aws_region
}

module "cloudwatch_logs" {
  source = "../../"

  project     = var.project
  environment = var.environment
  component   = "api"

  retention_in_days = 90
  log_group_class   = "STANDARD"

  metric_filters = [
    {
      name             = "error-count"
      pattern          = "ERROR"
      metric_namespace = "${var.project}/Logs"
      metric_name      = "ErrorCount"
      metric_value     = "1"
      default_value    = "0"
    },
    {
      name             = "latency-high"
      pattern          = "{ $.latency > 3000 }"
      metric_namespace = "${var.project}/Logs"
      metric_name      = "HighLatencyCount"
      metric_value     = "1"
      default_value    = "0"
    },
  ]

  subscription_filters = [
    {
      name            = "to-lambda"
      filter_pattern  = "ERROR"
      destination_arn = var.lambda_destination_arn
    },
  ]

  additional_tags = {
    Example = "complete"
  }
}
