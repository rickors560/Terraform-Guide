# API Gateway Component

Production-grade REST API Gateway with Lambda proxy integration, API key authentication, usage plans, CORS, and access logging.

## Features

- REST API with Lambda proxy integration
- CORS preflight handling (OPTIONS method with mock integration)
- API key and usage plan with monthly quota
- Throttling (burst and rate limits)
- CloudWatch access logging with structured JSON format
- Optional X-Ray tracing
- Custom domain ready (use the ACM component for certificates)

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply

# Test the API
curl -H "x-api-key: $(terraform output -raw api_key_value)" \
  "$(terraform output -raw invoke_url)/api/hello?name=World"
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `endpoint_type` | REGIONAL, EDGE, or PRIVATE | `string` | `REGIONAL` |
| `require_api_key` | Require API key | `bool` | `true` |
| `throttling_burst_limit` | Burst limit | `number` | `50` |
| `throttling_rate_limit` | Rate limit (rps) | `number` | `100` |

## Outputs

| Name | Description |
|------|-------------|
| `invoke_url` | API invocation URL |
| `api_key_value` | API key (sensitive) |
| `api_id` | REST API ID |
| `execution_arn` | Execution ARN |
