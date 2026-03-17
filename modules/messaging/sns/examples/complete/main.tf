provider "aws" {
  region = var.aws_region
}

module "sns_pubsub" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "order-events"

  display_name      = "Order Events"
  kms_master_key_id = "alias/aws/sns"

  subscriptions = [
    {
      name                 = "fulfillment-queue"
      protocol             = "sqs"
      endpoint             = var.fulfillment_queue_arn
      raw_message_delivery = true
      filter_policy = jsonencode({
        eventType = ["OrderCreated", "OrderShipped"]
      })
      filter_policy_scope = "MessageBody"
    },
    {
      name                 = "analytics-queue"
      protocol             = "sqs"
      endpoint             = var.analytics_queue_arn
      raw_message_delivery = true
    },
    {
      name     = "webhook-endpoint"
      protocol = "https"
      endpoint = var.webhook_url
      filter_policy = jsonencode({
        eventType = ["OrderCreated"]
      })
    },
  ]

  allowed_services  = ["events.amazonaws.com", "s3.amazonaws.com"]
  cross_account_ids = var.cross_account_ids

  additional_tags = {
    Example = "complete"
  }
}
