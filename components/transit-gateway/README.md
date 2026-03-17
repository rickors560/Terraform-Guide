# Transit Gateway Component

This component creates a Transit Gateway with three route tables (shared services, isolated, egress), VPC attachments with explicit route table associations and propagations implementing a hub-and-spoke topology, static default routes to the egress VPC, RFC1918 blackhole routes for security, and optional cross-account sharing via AWS RAM.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                           | Description                      | Type        | Default |
|--------------------------------|----------------------------------|-------------|---------|
| project_name                   | Project name for naming          | string      | n/a     |
| environment                    | Environment name                 | string      | n/a     |
| amazon_side_asn                | BGP ASN                          | number      | 64512   |
| vpc_attachments                | Map of VPC attachments           | map(object) | {}      |
| share_with_organization        | Share with org                   | bool        | false   |
| share_with_account_ids         | Accounts to share with           | list(string)| []      |

## Outputs

| Name                           | Description                     |
|--------------------------------|---------------------------------|
| transit_gateway_id             | ID of the Transit Gateway       |
| shared_services_route_table_id | Shared services route table ID  |
| isolated_route_table_id        | Isolated route table ID         |
| vpc_attachment_ids             | Map of attachment IDs           |
