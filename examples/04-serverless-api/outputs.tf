###############################################################################
# Outputs — 04-serverless-api
###############################################################################

output "api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "dev_invoke_url" {
  description = "Base URL for the dev stage"
  value       = aws_api_gateway_stage.dev.invoke_url
}

output "prod_invoke_url" {
  description = "Base URL for the prod stage"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "dev_items_url" {
  description = "Full URL for items endpoint (dev)"
  value       = "${aws_api_gateway_stage.dev.invoke_url}/items"
}

output "prod_items_url" {
  description = "Full URL for items endpoint (prod)"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/items"
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.items.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.items.arn
}

output "lambda_function_names" {
  description = "Lambda function names"
  value = {
    create_item = aws_lambda_function.create_item.function_name
    get_item    = aws_lambda_function.get_item.function_name
    list_items  = aws_lambda_function.list_items.function_name
    delete_item = aws_lambda_function.delete_item.function_name
  }
}

output "example_curl_commands" {
  description = "Example curl commands to test the API"
  value       = <<-EOT
    # Create an item
    curl -X POST ${aws_api_gateway_stage.dev.invoke_url}/items \
      -H "Content-Type: application/json" \
      -d '{"name": "Test Item", "description": "A test item"}'

    # List all items
    curl ${aws_api_gateway_stage.dev.invoke_url}/items

    # Get a specific item (replace <id>)
    curl ${aws_api_gateway_stage.dev.invoke_url}/items/<id>

    # Delete an item (replace <id>)
    curl -X DELETE ${aws_api_gateway_stage.dev.invoke_url}/items/<id>
  EOT
}
