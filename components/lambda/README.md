# Lambda Component

Production-grade Lambda function (Python 3.12) with IAM role, CloudWatch logging, API Gateway trigger, and monitoring alarms.

## Features

- Python 3.12 hello-world function with structured JSON responses
- IAM execution role with least-privilege CloudWatch Logs permissions
- Optional VPC connectivity
- Optional API Gateway REST API trigger with access logging
- CloudWatch alarms for errors, throttles, and duration
- Optional X-Ray tracing
- Configurable environment variables

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

After deployment, test the API:
```bash
curl $(terraform output -raw api_gateway_url)?name=Terraform
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `memory_size` | Memory (MB) | `number` | `128` |
| `timeout` | Timeout (seconds) | `number` | `30` |
| `log_level` | Log level | `string` | `INFO` |
| `tracing_mode` | X-Ray mode | `string` | `PassThrough` |
| `create_api_gateway` | Create API GW trigger | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `function_name` | Lambda function name |
| `function_arn` | Lambda ARN |
| `api_gateway_url` | API Gateway URL |
| `iam_role_arn` | Execution role ARN |
