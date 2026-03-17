################################################################################
# Dead-Letter Queue
################################################################################

resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                        = local.dlq_queue_name
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null
  message_retention_seconds   = var.dlq_message_retention_seconds
  kms_master_key_id           = var.kms_master_key_id
  sqs_managed_sse_enabled     = var.kms_master_key_id == null ? var.sqs_managed_sse_enabled : null

  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? var.kms_data_key_reuse_period_seconds : null

  tags = merge(local.common_tags, {
    Name = local.dlq_queue_name
  })
}

################################################################################
# Main Queue
################################################################################

resource "aws_sqs_queue" "this" {
  name                        = local.queue_name
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null
  deduplication_scope         = var.fifo_queue ? var.deduplication_scope : null
  fifo_throughput_limit       = var.fifo_queue ? var.fifo_throughput_limit : null

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? var.kms_data_key_reuse_period_seconds : null
  sqs_managed_sse_enabled           = var.kms_master_key_id == null ? var.sqs_managed_sse_enabled : null

  policy = var.policy

  redrive_policy = var.create_dlq || var.existing_dlq_arn != null ? jsonencode({
    deadLetterTargetArn = var.create_dlq ? aws_sqs_queue.dlq[0].arn : var.existing_dlq_arn
    maxReceiveCount     = var.dlq_max_receive_count
  }) : null

  redrive_allow_policy = var.redrive_allow_policy

  tags = merge(local.common_tags, {
    Name = local.queue_name
  })
}

################################################################################
# Queue Policy for Main Queue (if provided)
################################################################################

resource "aws_sqs_queue_policy" "this" {
  count = var.policy != null ? 1 : 0

  queue_url = aws_sqs_queue.this.id
  policy    = var.policy
}
