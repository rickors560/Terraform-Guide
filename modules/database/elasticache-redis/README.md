# ElastiCache Redis Module

Terraform module to create an AWS ElastiCache Redis replication group with cluster mode, encryption, automatic failover, and snapshot configuration.

## Features

- Redis replication group with configurable engine version
- Cluster mode toggle (sharding)
- Configurable node type and number of clusters
- Subnet group and parameter group
- At-rest and in-transit encryption with optional KMS
- Auth token support
- Automatic failover and Multi-AZ
- Snapshot retention and maintenance window
- SNS notification support

## Usage

```hcl
module "redis" {
  source = "../../modules/database/elasticache-redis"

  project     = "myapp"
  environment = "prod"

  engine_version     = "7.1"
  node_type          = "cache.r6g.large"
  num_cache_clusters = 3

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token

  automatic_failover_enabled = true
  multi_az_enabled           = true

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
| primary_endpoint_address | Primary endpoint |
| reader_endpoint_address | Reader endpoint |
| replication_group_id | Replication group ID |
