# Example 05 — Container App: ECS Fargate + ALB + ECR + RDS

A containerized application running on ECS Fargate behind an Application Load Balancer, with an ECR repository for images and RDS PostgreSQL for persistence.

## Architecture

```mermaid
graph TB
    Internet((Internet))

    subgraph VPC["VPC 10.0.0.0/16"]
        subgraph Public["Public Subnets (2 AZs)"]
            ALB["Application<br/>Load Balancer<br/>:80"]
            NAT["NAT Gateway"]
        end

        subgraph Private["Private Subnets (2 AZs)"]
            ECS["ECS Fargate Service<br/>256 CPU / 512 MEM<br/>nginx container<br/>Auto-scaling 1-4"]
        end

        subgraph Database["Database Subnets (2 AZs)"]
            RDS["RDS PostgreSQL<br/>db.t3.micro<br/>:5432"]
        end

        IGW["Internet Gateway"]
    end

    ECR["ECR Repository"]

    Internet -->|HTTP| IGW
    IGW --> ALB
    ALB -->|:80| ECS
    ECS -->|:5432| RDS
    ECS -->|outbound| NAT
    NAT --> IGW
    ECR -.->|pull image| ECS

    style VPC fill:#f0f4ff,stroke:#3b82f6,stroke-width:2px
    style Public fill:#d1fae5,stroke:#10b981,stroke-width:1px
    style Private fill:#fef3c7,stroke:#f59e0b,stroke-width:1px
    style Database fill:#fce7f3,stroke:#ec4899,stroke-width:1px
    style ALB fill:#dbeafe,stroke:#3b82f6,stroke-width:2px
    style ECS fill:#fef9c3,stroke:#eab308,stroke-width:2px
    style RDS fill:#fce7f3,stroke:#ec4899,stroke-width:2px
    style ECR fill:#e0e7ff,stroke:#6366f1,stroke-width:1px
```

## What Gets Created

| Resource | Description |
|----------|-------------|
| VPC | Full networking with public, private, and database subnets |
| NAT Gateway | Outbound internet for Fargate tasks |
| ALB | Application Load Balancer with health checks |
| ECR Repository | Container image registry with lifecycle policy |
| ECS Cluster | Fargate cluster with Container Insights |
| Task Definition | 256 CPU, 512 MEM, nginx placeholder |
| ECS Service | Fargate service with deployment circuit breaker |
| Auto Scaling | CPU (60%) and memory (70%) target tracking |
| RDS PostgreSQL | Single-AZ, encrypted, db.t3.micro |
| Security Groups | ALB -> ECS -> RDS chain |
| CloudWatch Logs | Container log group |

## Prerequisites

- Terraform >= 1.9.0
- AWS CLI configured with appropriate credentials
- Docker (for building and pushing images)

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars

# Deploy infrastructure (starts with nginx placeholder)
make apply

# Build and push your app image
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin <account_id>.dkr.ecr.ap-south-1.amazonaws.com

docker build -t <ecr_repo_url>:latest .
docker push <ecr_repo_url>:latest

# Update the service
aws ecs update-service --cluster container-app-cluster \
  --service container-app-service --force-new-deployment

make destroy
```

## Cost Estimate

| Resource | Monthly Cost (ap-south-1) |
|----------|--------------------------|
| ALB | ~$22.00 |
| Fargate (256 CPU, 512 MEM) x2 | ~$18.00 |
| NAT Gateway | ~$32.40 |
| RDS db.t3.micro | ~$14.00 |
| ECR (1 GB) | ~$0.10 |
| CloudWatch Logs (1 GB) | ~$0.50 |
| **Total** | **~$87.00/month** |

## Cleanup

```bash
make destroy
make clean
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| aws_region | AWS region | string | ap-south-1 |
| project_name | Project name | string | container-app |
| container_image | Docker image | string | nginx:alpine |
| container_port | Container port | number | 80 |
| task_cpu | Fargate CPU | number | 256 |
| task_memory | Fargate memory | number | 512 |
| desired_count | Desired tasks | number | 2 |
| db_password | Database password | string | — |

## Outputs

| Name | Description |
|------|-------------|
| app_url | Application URL via ALB |
| ecr_repository_url | ECR repository URL |
| ecr_login_command | Docker ECR login command |
| rds_endpoint | RDS endpoint |
| deploy_command | ECS force-redeploy command |
