# DynamoDB Module

Terraform module to create an AWS DynamoDB table with GSI/LSI support, TTL, PITR, encryption, streams, and auto-scaling.

## Features

- Hash key and optional range key
- PAY_PER_REQUEST or PROVISIONED billing mode with auto-scaling
- Global Secondary Indexes (GSI) and Local Secondary Indexes (LSI)
- TTL configuration
- Point-in-time recovery
- Server-side encryption (AWS owned or CMK)
- DynamoDB Streams
- Deletion protection

## Usage

```hcl
module "dynamodb" {
  source = "../../modules/database/dynamodb"

  project            = "myapp"
  environment        = "prod"
  table_name_suffix  = "orders"

  hash_key      = "PK"
  hash_key_type = "S"
  range_key      = "SK"
  range_key_type = "S"

  billing_mode = "PAY_PER_REQUEST"
  ttl_attribute = "expires_at"

  global_secondary_indexes = [
    {
      name            = "GSI1"
      hash_key        = "GSI1PK"
      hash_key_type   = "S"
      range_key       = "GSI1SK"
      range_key_type  = "S"
      projection_type = "ALL"
    }
  ]

  team = "platform"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Outputs

| Name | Description |
|------|-------------|
| table_name | Table name |
| table_arn | Table ARN |
| table_stream_arn | Stream ARN |
