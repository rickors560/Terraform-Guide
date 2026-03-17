# Database Modules

Terraform modules for provisioning and managing AWS database services including relational databases (RDS, Aurora), NoSQL (DynamoDB), and in-memory caches (ElastiCache Redis).

## Sub-Modules

| Module | Description |
|--------|-------------|
| [rds-postgres](./rds-postgres/) | RDS PostgreSQL with Multi-AZ, encryption, automated backups, Performance Insights, and Secrets Manager integration |
| [aurora](./aurora/) | Aurora PostgreSQL cluster with Serverless v2 scaling, global database support, encryption, and IAM authentication |
| [dynamodb](./dynamodb/) | DynamoDB table with GSI/LSI support, TTL, PITR, encryption, streams, and auto-scaling |
| [elasticache-redis](./elasticache-redis/) | ElastiCache Redis replication group with cluster mode, encryption, automatic failover, and snapshots |

## How They Relate

Each database module is largely independent, serving different use cases:

- **rds-postgres** and **aurora** both provide relational PostgreSQL databases. Use RDS for single-instance workloads; use Aurora for higher availability, read replicas, or serverless scaling.
- **dynamodb** provides key-value and document storage for high-throughput, low-latency workloads.
- **elasticache-redis** provides an in-memory cache or session store, commonly deployed alongside RDS/Aurora to reduce database load.

All database modules expect VPC subnet IDs and security group IDs as inputs, connecting them to the networking layer.

## Usage Example

```hcl
module "aurora_cluster" {
  source = "../../modules/database/aurora"

  project     = "myapp"
  environment = "prod"

  engine_version = "16.3"
  instance_class = "db.r6g.large"
  instance_count = 2

  subnet_ids             = module.vpc.database_subnet_ids
  vpc_security_group_ids = [module.db_sg.security_group_id]

  team        = "platform"
  cost_center = "CC-1234"
}

module "cache" {
  source = "../../modules/database/elasticache-redis"

  project     = "myapp"
  environment = "prod"

  node_type       = "cache.r6g.large"
  num_cache_nodes = 2
  subnet_ids      = module.vpc.private_subnet_ids
  security_group_ids = [module.cache_sg.security_group_id]

  automatic_failover_enabled = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  team = "platform"
}

module "sessions_table" {
  source = "../../modules/database/dynamodb"

  project     = "myapp"
  environment = "prod"
  table_name  = "sessions"

  hash_key  = "session_id"
  hash_key_type = "S"

  ttl_attribute = "expires_at"
  enable_pitr   = true

  team = "platform"
}
```
