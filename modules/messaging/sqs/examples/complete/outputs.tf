output "standard_queue_url" {
  description = "URL of the standard queue."
  value       = module.sqs_standard.queue_url
}

output "standard_queue_arn" {
  description = "ARN of the standard queue."
  value       = module.sqs_standard.queue_arn
}

output "standard_dlq_url" {
  description = "URL of the standard DLQ."
  value       = module.sqs_standard.dlq_url
}

output "fifo_queue_url" {
  description = "URL of the FIFO queue."
  value       = module.sqs_fifo.queue_url
}

output "fifo_queue_arn" {
  description = "ARN of the FIFO queue."
  value       = module.sqs_fifo.queue_arn
}
