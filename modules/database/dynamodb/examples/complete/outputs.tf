output "table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = module.dynamodb.table_arn
}
