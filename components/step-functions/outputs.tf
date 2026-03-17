# -----------------------------------------------------------------------------
# Step Functions Component - Outputs
# -----------------------------------------------------------------------------

output "state_machine_arn" {
  description = "ARN of the order processing state machine"
  value       = aws_sfn_state_machine.order_processing.arn
}

output "state_machine_name" {
  description = "Name of the order processing state machine"
  value       = aws_sfn_state_machine.order_processing.name
}

output "execution_role_arn" {
  description = "ARN of the Step Functions execution role"
  value       = aws_iam_role.step_functions.arn
}

output "validate_order_function_arn" {
  description = "ARN of the validate order Lambda function"
  value       = aws_lambda_function.validate_order.arn
}

output "process_payment_function_arn" {
  description = "ARN of the process payment Lambda function"
  value       = aws_lambda_function.process_payment.arn
}

output "update_inventory_function_arn" {
  description = "ARN of the update inventory Lambda function"
  value       = aws_lambda_function.update_inventory.arn
}

output "send_notification_function_arn" {
  description = "ARN of the send notification Lambda function"
  value       = aws_lambda_function.send_notification.arn
}

output "log_group_name" {
  description = "Name of the Step Functions CloudWatch log group"
  value       = aws_cloudwatch_log_group.step_functions.name
}
