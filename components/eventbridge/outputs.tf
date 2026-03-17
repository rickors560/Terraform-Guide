###############################################################################
# EventBridge Component — Outputs
###############################################################################

output "event_bus_name" {
  description = "Name of the custom event bus"
  value       = aws_cloudwatch_event_bus.main.name
}

output "event_bus_arn" {
  description = "ARN of the custom event bus"
  value       = aws_cloudwatch_event_bus.main.arn
}

output "custom_events_rule_arn" {
  description = "ARN of the custom events rule"
  value       = aws_cloudwatch_event_rule.custom_events.arn
}

output "scheduled_rule_arn" {
  description = "ARN of the scheduled rule"
  value       = aws_cloudwatch_event_rule.scheduled.arn
}

output "event_handler_function_name" {
  description = "Name of the event handler Lambda function"
  value       = aws_lambda_function.event_handler.function_name
}

output "event_handler_function_arn" {
  description = "ARN of the event handler Lambda function"
  value       = aws_lambda_function.event_handler.arn
}

output "event_queue_url" {
  description = "URL of the event target SQS queue"
  value       = aws_sqs_queue.event_target.url
}

output "event_queue_arn" {
  description = "ARN of the event target SQS queue"
  value       = aws_sqs_queue.event_target.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue"
  value       = aws_sqs_queue.event_dlq.url
}

output "archive_name" {
  description = "Name of the event archive"
  value       = aws_cloudwatch_event_archive.main.name
}
