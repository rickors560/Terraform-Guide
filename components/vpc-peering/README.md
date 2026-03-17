# VPC Peering Component

This component creates a VPC peering connection between two VPCs with DNS resolution enabled, route table entries on both sides, security group rules for cross-VPC traffic, and support for cross-account and cross-region peering via a secondary provider.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                         | Description                      | Type        | Default |
|------------------------------|----------------------------------|-------------|---------|
| requester_vpc_id             | Requester VPC ID                 | string      | n/a     |
| requester_vpc_cidr           | Requester CIDR block             | string      | n/a     |
| accepter_vpc_id              | Accepter VPC ID                  | string      | n/a     |
| accepter_vpc_cidr            | Accepter CIDR block              | string      | n/a     |
| peer_account_id              | Peer AWS account ID              | string      | ""      |
| peer_region                  | Peer AWS region                  | string      | ""      |
| requester_route_table_ids    | Requester route tables           | list(string)| []      |
| accepter_route_table_ids     | Accepter route tables            | list(string)| []      |

## Outputs

| Name                      | Description                     |
|---------------------------|---------------------------------|
| peering_connection_id     | ID of the peering connection    |
| peering_connection_status | Status of the connection        |
