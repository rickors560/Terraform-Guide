output "table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.this.id
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.this.arn
}

output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.this.name
}

output "table_hash_key" {
  description = "Hash key of the table"
  value       = aws_dynamodb_table.this.hash_key
}

output "table_range_key" {
  description = "Range key of the table"
  value       = aws_dynamodb_table.this.range_key
}

output "table_stream_arn" {
  description = "Stream ARN of the table"
  value       = var.stream_enabled ? aws_dynamodb_table.this.stream_arn : null
}

output "table_stream_label" {
  description = "Stream label of the table"
  value       = var.stream_enabled ? aws_dynamodb_table.this.stream_label : null
}
