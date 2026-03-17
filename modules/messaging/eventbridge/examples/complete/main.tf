provider "aws" {
  region = var.aws_region
}

module "eventbridge" {
  source = "../../"

  project     = var.project
  environment = var.environment
  bus_name    = "application"

  rules = [
    {
      name        = "order-created"
      description = "Triggered when a new order is created"
      event_pattern = jsonencode({
        source      = ["myapp.orders"]
        detail-type = ["OrderCreated"]
      })
      targets = [
        {
          target_id       = "process-order-lambda"
          arn             = var.process_order_lambda_arn
          dead_letter_arn = var.dlq_arn
          retry_policy = {
            maximum_event_age_in_seconds = 3600
            maximum_retry_attempts       = 3
          }
        },
        {
          target_id = "order-queue"
          arn       = var.order_queue_arn
          input_transformer = {
            input_paths = {
              orderId = "$.detail.orderId"
              status  = "$.detail.status"
            }
            input_template = "\"Order <orderId> has status <status>\""
          }
        },
      ]
    },
    {
      name                = "daily-report"
      description         = "Generate daily report at 8 AM UTC"
      schedule_expression = "cron(0 8 * * ? *)"
      targets = [
        {
          target_id = "report-lambda"
          arn       = var.report_lambda_arn
          input     = jsonencode({ reportType = "daily" })
        },
      ]
    },
  ]

  archives = [
    {
      name           = "all-events"
      description    = "Archive of all events for replay"
      retention_days = 90
    },
  ]

  additional_tags = {
    Example = "complete"
  }
}
