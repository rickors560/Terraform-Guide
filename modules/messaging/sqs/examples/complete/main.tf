provider "aws" {
  region = var.aws_region
}

module "sqs_standard" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "orders"

  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  max_message_size           = 262144
  delay_seconds              = 0
  receive_wait_time_seconds  = 10

  create_dlq            = true
  dlq_max_receive_count = 5

  sqs_managed_sse_enabled = true

  additional_tags = {
    Example = "complete"
  }
}

module "sqs_fifo" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "events"

  fifo_queue                  = true
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400

  create_dlq            = true
  dlq_max_receive_count = 3

  sqs_managed_sse_enabled = true

  additional_tags = {
    Example = "complete"
  }
}
