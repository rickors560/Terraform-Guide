# -----------------------------------------------------------------------------
# SNS Alarms Component - Outputs
# -----------------------------------------------------------------------------

output "critical_topic_arn" {
  description = "ARN of the critical alerts SNS topic"
  value       = aws_sns_topic.critical.arn
}

output "critical_topic_name" {
  description = "Name of the critical alerts SNS topic"
  value       = aws_sns_topic.critical.name
}

output "warning_topic_arn" {
  description = "ARN of the warning alerts SNS topic"
  value       = aws_sns_topic.warning.arn
}

output "warning_topic_name" {
  description = "Name of the warning alerts SNS topic"
  value       = aws_sns_topic.warning.name
}

output "info_topic_arn" {
  description = "ARN of the info alerts SNS topic"
  value       = aws_sns_topic.info.arn
}

output "info_topic_name" {
  description = "Name of the info alerts SNS topic"
  value       = aws_sns_topic.info.name
}

output "alarm_processor_function_arn" {
  description = "ARN of the alarm processor Lambda function"
  value       = aws_lambda_function.alarm_processor.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for SNS encryption"
  value       = aws_kms_key.sns.arn
}

output "all_topic_arns" {
  description = "List of all SNS topic ARNs for use in alarm configurations"
  value = [
    aws_sns_topic.critical.arn,
    aws_sns_topic.warning.arn,
    aws_sns_topic.info.arn
  ]
}
