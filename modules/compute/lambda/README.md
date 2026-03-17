# Lambda Function Module

Terraform module to create an AWS Lambda function with IAM role, CloudWatch log group, VPC configuration, dead letter queue, layers, and event source mappings.

## Features

- Lambda function from zip file or S3
- Runtime, handler, memory, and timeout configuration
- Environment variables support
- Optional VPC configuration
- IAM role with basic execution policy and VPC access
- CloudWatch log group with configurable retention
- Dead letter queue (SQS/SNS)
- Reserved concurrency control
- Lambda layers support
- Event source mapping for stream-based triggers
- ARM64/x86_64 architecture support

## Usage

```hcl
module "lambda" {
  source = "../../modules/compute/lambda"

  project              = "myapp"
  environment          = "prod"
  function_name_suffix = "processor"

  runtime     = "python3.12"
  handler     = "main.handler"
  memory_size = 256
  timeout     = 60
  filename    = "lambda.zip"

  environment_variables = {
    TABLE_NAME = "my-table"
    LOG_LEVEL  = "INFO"
  }

  log_retention_days             = 30
  reserved_concurrent_executions = 100

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
| function_name | Lambda function name |
| function_arn | Lambda function ARN |
| invoke_arn | Invoke ARN |
| role_arn | Execution role ARN |
| log_group_name | CloudWatch log group name |
