# NAT Gateway Component

This component creates public NAT Gateways with Elastic IPs in a high-availability multi-AZ configuration (or single NAT for cost savings), private route tables with default routes, subnet associations, an optional private NAT Gateway for VPC-to-VPC traffic, and CloudWatch alarms for port allocation errors, packet drops, and bandwidth.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                | Description                      | Type         | Default |
|---------------------|----------------------------------|--------------|---------|
| project_name        | Project name for naming          | string       | n/a     |
| environment         | Environment name                 | string       | n/a     |
| vpc_id              | VPC ID                           | string       | n/a     |
| public_subnet_ids   | Public subnets for NAT GWs      | list(string) | n/a     |
| private_subnet_ids  | Private subnets to route         | list(string) | n/a     |
| high_availability   | One NAT per AZ                   | bool         | true    |

## Outputs

| Name                   | Description                  |
|------------------------|------------------------------|
| nat_gateway_ids        | List of NAT Gateway IDs      |
| nat_gateway_public_ips | Public IPs of NAT Gateways   |
| private_route_table_ids| Private route table IDs      |
