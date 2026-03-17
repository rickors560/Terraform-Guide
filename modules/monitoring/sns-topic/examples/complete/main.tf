provider "aws" {
  region = var.aws_region
}

module "sns_topic" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "notifications"

  display_name      = "Application Notifications"
  kms_master_key_id = "alias/aws/sns"

  subscriptions = [
    {
      protocol = "email"
      endpoint = var.notification_email
    },
    {
      protocol = "sqs"
      endpoint = var.sqs_queue_arn
      raw_message_delivery = true
    },
  ]

  additional_tags = {
    Example = "complete"
  }
}
