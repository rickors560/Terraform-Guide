################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

################################################################################
# SNS Topic
################################################################################

resource "aws_sns_topic" "this" {
  name                        = local.topic_name
  display_name                = var.display_name != "" ? var.display_name : null
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null
  kms_master_key_id           = var.kms_master_key_id
  delivery_policy             = var.delivery_policy
  tracing_config              = var.tracing_config
  archive_policy              = var.archive_policy

  tags = merge(local.common_tags, {
    Name = local.topic_name
  })
}

################################################################################
# Topic Policy for Cross-Account and Service Access
################################################################################

resource "aws_sns_topic_policy" "this" {
  count = var.policy != null || length(var.cross_account_ids) > 0 || length(var.allowed_services) > 0 ? 1 : 0

  arn = aws_sns_topic.this.arn

  policy = var.policy != null ? var.policy : jsonencode({
    Version = "2012-10-17"
    Id      = "${local.topic_name}-policy"
    Statement = concat(
      [
        {
          Sid    = "DefaultAccountAccess"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          }
          Action = [
            "sns:Publish",
            "sns:Subscribe",
            "sns:SetTopicAttributes",
            "sns:RemovePermission",
            "sns:AddPermission",
            "sns:GetTopicAttributes",
            "sns:ListSubscriptionsByTopic"
          ]
          Resource = aws_sns_topic.this.arn
        }
      ],
      length(var.cross_account_ids) > 0 ? [
        {
          Sid    = "CrossAccountPublish"
          Effect = "Allow"
          Principal = {
            AWS = [for id in var.cross_account_ids : "arn:aws:iam::${id}:root"]
          }
          Action   = ["sns:Publish", "sns:Subscribe"]
          Resource = aws_sns_topic.this.arn
        }
      ] : [],
      length(var.allowed_services) > 0 ? [
        {
          Sid    = "AllowServicePublish"
          Effect = "Allow"
          Principal = {
            Service = var.allowed_services
          }
          Action   = "sns:Publish"
          Resource = aws_sns_topic.this.arn
        }
      ] : [],
    )
  })
}

################################################################################
# Subscriptions
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
  replay_policy                   = each.value.replay_policy
}
