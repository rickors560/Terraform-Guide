# VPC Component

Production-grade AWS VPC with multi-tier subnet architecture, NAT Gateway, and VPC Flow Logs.

## Architecture

- **Public subnets** (one per AZ) with Internet Gateway route and auto-assign public IPs
- **Private subnets** (one per AZ) with NAT Gateway route for outbound internet
- **Database subnets** (one per AZ) fully isolated with restrictive NACLs
- **VPC Flow Logs** shipped to CloudWatch Logs for network traffic auditing

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_vpc` | Main VPC with DNS support and hostnames enabled |
| `aws_internet_gateway` | Internet access for public subnets |
| `aws_nat_gateway` | Outbound internet for private subnets (single or per-AZ) |
| `aws_subnet` | Public, private, and database subnets across AZs |
| `aws_route_table` | Separate route tables for each tier |
| `aws_network_acl` | NACLs for public and database subnets |
| `aws_db_subnet_group` | Subnet group for RDS/Aurora deployments |
| `aws_flow_log` | VPC flow logs to CloudWatch |
| `aws_cloudwatch_log_group` | Log group for flow logs |
| `aws_iam_role` | IAM role for flow log delivery |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Cost Considerations

- **NAT Gateway**: ~$32/month per gateway plus data processing charges. Use `single_nat_gateway = true` for dev/staging.
- **Flow Logs**: CloudWatch Logs ingestion and storage charges apply.
- **Elastic IPs**: Free when associated with a running NAT Gateway.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `aws_region` | AWS region | `string` | `ap-south-1` |
| `project_name` | Project name for tagging | `string` | — |
| `environment` | Environment (dev/staging/prod) | `string` | — |
| `vpc_cidr` | VPC CIDR block | `string` | `10.0.0.0/16` |
| `az_count` | Number of AZs (2 or 3) | `number` | `3` |
| `single_nat_gateway` | Use one NAT for all AZs | `bool` | `true` |
| `flow_log_retention_days` | Flow log retention | `number` | `30` |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | Public subnet IDs |
| `private_subnet_ids` | Private subnet IDs |
| `database_subnet_ids` | Database subnet IDs |
| `database_subnet_group_name` | DB subnet group name |
| `nat_gateway_public_ips` | NAT Gateway EIPs |
| `availability_zones` | AZs in use |
