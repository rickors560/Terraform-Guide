################################################################################
# SNS Topic
################################################################################

resource "aws_sns_topic" "this" {
  name                        = local.topic_name
  display_name                = var.display_name != "" ? var.display_name : null
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null
  kms_master_key_id           = var.kms_master_key_id
  signature_version           = var.signature_version
  tracing_config              = var.tracing_config
  delivery_policy             = var.delivery_policy
  policy                      = var.policy

  tags = local.common_tags
}

################################################################################
# SNS Subscriptions
################################################################################

resource "aws_sns_topic_subscription" "this" {
  for_each = local.subscriptions_map

  topic_arn                       = aws_sns_topic.this.arn
  protocol                        = each.value.protocol
  endpoint                        = each.value.endpoint
  endpoint_auto_confirms          = each.value.endpoint_auto_confirms
  raw_message_delivery            = each.value.raw_message_delivery
  filter_policy                   = each.value.filter_policy
  filter_policy_scope             = each.value.filter_policy_scope
  redrive_policy                  = each.value.redrive_policy
  delivery_policy                 = each.value.delivery_policy
  subscription_role_arn           = each.value.subscription_role_arn
  confirmation_timeout_in_minutes = each.value.confirmation_timeout_in_minutes
}
