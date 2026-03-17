###############################################################################
# Lambda Component — Outputs
###############################################################################

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.main.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.main.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.main.invoke_arn
}

output "function_version" {
  description = "Published version of the Lambda function"
  value       = aws_lambda_function.main.version
}

output "iam_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda.arn
}

output "iam_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda.name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.lambda.arn
}

output "api_gateway_url" {
  description = "API Gateway invocation URL (if created)"
  value       = var.create_api_gateway ? "${aws_api_gateway_stage.main[0].invoke_url}/" : null
}

output "api_gateway_id" {
  description = "API Gateway REST API ID (if created)"
  value       = var.create_api_gateway ? aws_api_gateway_rest_api.main[0].id : null
}

output "api_gateway_execution_arn" {
  description = "API Gateway execution ARN (if created)"
  value       = var.create_api_gateway ? aws_api_gateway_rest_api.main[0].execution_arn : null
}
