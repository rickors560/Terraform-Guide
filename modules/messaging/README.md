# Messaging Modules

Terraform modules for AWS messaging and event-driven architectures including queues (SQS), pub/sub topics (SNS), and event buses (EventBridge).

## Sub-Modules

| Module | Description |
|--------|-------------|
| [sqs](./sqs/) | SQS queues with dead-letter queue support, encryption, and access policies |
| [sns](./sns/) | SNS Topics for pub/sub messaging with message filtering, cross-account access, and FIFO support |
| [eventbridge](./eventbridge/) | EventBridge event buses, rules, targets, and archives |

## How They Relate

```
eventbridge ----> sns ----> sqs (event-driven pipeline)
    |              |         |
    v              v         v
  Lambda        Lambda    Lambda / ECS / EC2
```

- **eventbridge** captures events from AWS services or custom applications and routes them to targets based on rules. Targets can include SNS topics, SQS queues, or Lambda functions.
- **sns** provides fan-out pub/sub messaging. A single message published to an SNS topic can be delivered to multiple SQS queues, Lambda functions, or HTTP endpoints.
- **sqs** provides reliable message queuing with at-least-once delivery. Commonly used as a buffer between producers and consumers, with dead-letter queues for failed messages.

A typical pattern: EventBridge captures an event, routes it to an SNS topic, which fans out to multiple SQS queues consumed by different services.

## Usage Example

```hcl
module "orders_queue" {
  source = "../../modules/messaging/sqs"

  project     = "myapp"
  environment = "prod"
  name_suffix = "orders"

  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400

  enable_dlq         = true
  dlq_max_receive_count = 3

  team = "platform"
}

module "orders_topic" {
  source = "../../modules/messaging/sns"

  project     = "myapp"
  environment = "prod"
  name_suffix = "orders"

  subscriptions = [
    {
      protocol = "sqs"
      endpoint = module.orders_queue.queue_arn
    }
  ]

  team = "platform"
}

module "order_events" {
  source = "../../modules/messaging/eventbridge"

  project     = "myapp"
  environment = "prod"

  rules = [
    {
      name        = "order-created"
      description = "Matches order creation events"
      event_pattern = jsonencode({
        source      = ["myapp.orders"]
        detail-type = ["OrderCreated"]
      })
      targets = [
        {
          arn = module.orders_topic.topic_arn
        }
      ]
    }
  ]

  team = "platform"
}
```
