# Internet Gateway Component

This component creates a VPC with an Internet Gateway, multi-AZ public subnets with auto-assign public IP, a public route table with default route to the IGW, a Network ACL allowing HTTP/HTTPS/SSH/ephemeral traffic, and VPC flow logs to CloudWatch.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                    | Description                 | Type   | Default    |
|-------------------------|-----------------------------|--------|------------|
| project_name            | Project name for naming     | string | n/a        |
| environment             | Environment name            | string | n/a        |
| vpc_cidr                | VPC CIDR block              | string | 10.0.0.0/16|
| az_count                | Number of AZs               | number | 3          |
| ssh_allowed_cidr        | SSH source CIDR             | string | 0.0.0.0/0  |
| flow_log_retention_days | Flow log retention          | number | 14         |

## Outputs

| Name                 | Description                |
|----------------------|----------------------------|
| vpc_id               | ID of the VPC              |
| internet_gateway_id  | ID of the IGW              |
| public_subnet_ids    | List of public subnet IDs  |
| public_route_table_id| ID of the public route table|
