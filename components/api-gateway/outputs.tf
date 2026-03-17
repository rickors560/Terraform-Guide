###############################################################################
# API Gateway Component — Outputs
###############################################################################

output "api_id" {
  description = "REST API ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_arn" {
  description = "REST API ARN"
  value       = aws_api_gateway_rest_api.main.arn
}

output "execution_arn" {
  description = "Execution ARN for Lambda permissions"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "invoke_url" {
  description = "Base invoke URL for the stage"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "stage_name" {
  description = "Deployed stage name"
  value       = aws_api_gateway_stage.main.stage_name
}

output "api_key_id" {
  description = "API Key ID (if created)"
  value       = var.require_api_key ? aws_api_gateway_api_key.main[0].id : null
}

output "api_key_value" {
  description = "API Key value (if created)"
  value       = var.require_api_key ? aws_api_gateway_api_key.main[0].value : null
  sensitive   = true
}

output "lambda_function_name" {
  description = "Name of the backend Lambda function"
  value       = aws_lambda_function.api_handler.function_name
}

output "lambda_function_arn" {
  description = "ARN of the backend Lambda function"
  value       = aws_lambda_function.api_handler.arn
}
