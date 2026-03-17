# Example 04 — Serverless API: API Gateway + Lambda + DynamoDB

A fully serverless REST API with CRUD operations. Four Lambda functions back a REST API Gateway, storing data in DynamoDB with pay-per-request billing.

## Architecture

```mermaid
graph LR
    Client((Client))

    subgraph APIGW["API Gateway (REST)"]
        DEV["dev stage"]
        PROD["prod stage"]
    end

    subgraph Lambda["Lambda Functions (Python 3.12)"]
        CREATE["create_item<br/>POST /items"]
        GET["get_item<br/>GET /items/{id}"]
        LIST["list_items<br/>GET /items"]
        DELETE["delete_item<br/>DELETE /items/{id}"]
    end

    subgraph DDB["DynamoDB"]
        TABLE["items table<br/>hash_key: id<br/>PAY_PER_REQUEST"]
    end

    CW["CloudWatch<br/>Logs"]

    Client --> DEV
    Client --> PROD
    DEV --> CREATE
    DEV --> GET
    DEV --> LIST
    DEV --> DELETE
    PROD --> CREATE
    PROD --> GET
    PROD --> LIST
    PROD --> DELETE
    CREATE --> TABLE
    GET --> TABLE
    LIST --> TABLE
    DELETE --> TABLE
    CREATE -.-> CW
    GET -.-> CW
    LIST -.-> CW
    DELETE -.-> CW

    style APIGW fill:#dbeafe,stroke:#3b82f6,stroke-width:2px
    style Lambda fill:#fef3c7,stroke:#f59e0b,stroke-width:2px
    style DDB fill:#d1fae5,stroke:#10b981,stroke-width:2px
    style CW fill:#f3e8ff,stroke:#a855f7,stroke-width:1px
```

## API Endpoints

| Method | Path | Lambda | Description |
|--------|------|--------|-------------|
| POST | /items | create_item | Create a new item |
| GET | /items | list_items | List all items |
| GET | /items/{id} | get_item | Get item by ID |
| DELETE | /items/{id} | delete_item | Delete item by ID |

## What Gets Created

| Resource | Description |
|----------|-------------|
| DynamoDB Table | Pay-per-request, point-in-time recovery enabled |
| IAM Role | Lambda execution role with DynamoDB permissions |
| Lambda Functions (x4) | Python 3.12, 128MB, 10s timeout |
| API Gateway REST API | Regional endpoint |
| API Gateway Stages | dev and prod with CloudWatch logging |
| CloudWatch Log Groups | One per Lambda + one per stage |

## Prerequisites

- Terraform >= 1.9.0
- AWS CLI configured with appropriate credentials

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars

make apply

# Test the API
# Create
curl -X POST $(terraform output -raw dev_invoke_url)/items \
  -H "Content-Type: application/json" \
  -d '{"name": "My Item", "description": "Hello from Lambda"}'

# List
curl $(terraform output -raw dev_invoke_url)/items

# Get (replace <id> with actual UUID)
curl $(terraform output -raw dev_invoke_url)/items/<id>

# Delete
curl -X DELETE $(terraform output -raw dev_invoke_url)/items/<id>

# Or run automated test
make test

make destroy
```

## Cost Estimate

| Resource | Monthly Cost |
|----------|-------------|
| Lambda (1M requests) | ~$0.20 |
| API Gateway (1M requests) | ~$3.50 |
| DynamoDB (1M reads + 1M writes) | ~$1.50 |
| CloudWatch Logs (1 GB) | ~$0.50 |
| **Total** | **~$5.70/month** |

> All services have generous Free Tier allowances. Actual costs depend on usage.

## Cleanup

```bash
make destroy
make clean
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| aws_region | AWS region | string | ap-south-1 |
| project_name | Project name | string | serverless-api |
| environment | Environment | string | dev |

## Outputs

| Name | Description |
|------|-------------|
| dev_invoke_url | Dev stage base URL |
| prod_invoke_url | Prod stage base URL |
| dynamodb_table_name | DynamoDB table name |
| lambda_function_names | Map of all Lambda function names |
| example_curl_commands | Ready-to-use curl commands |
