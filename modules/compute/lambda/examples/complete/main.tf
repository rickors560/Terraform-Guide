provider "aws" {
  region = var.aws_region
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/src/main.py"
  output_path = "${path.module}/lambda.zip"
}

module "lambda" {
  source = "../../"

  project              = var.project
  environment          = var.environment
  function_name_suffix = "processor"
  description          = "Example Lambda function for data processing"

  runtime       = "python3.12"
  handler       = "main.handler"
  memory_size   = 256
  timeout       = 60
  architectures = ["x86_64"]

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment_variables = {
    ENVIRONMENT = var.environment
    LOG_LEVEL   = "INFO"
  }

  log_retention_days             = 30
  reserved_concurrent_executions = 100

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
