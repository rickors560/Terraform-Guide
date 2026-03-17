# NACL Component

This component creates Network ACLs for a three-tier architecture: public (HTTP/HTTPS/SSH/ephemeral), private application (ALB traffic, SSH from bastion, ephemeral, DB/cache egress), and private database (DB port from app subnets only, replication, HTTPS for AWS APIs). All NACLs include explicit deny rules and proper ephemeral port handling for stateless return traffic.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                     | Description                  | Type         | Default    |
|--------------------------|------------------------------|--------------|------------|
| project_name             | Project name for naming      | string       | n/a        |
| environment              | Environment name             | string       | n/a        |
| vpc_id                   | VPC ID                       | string       | n/a        |
| vpc_cidr                 | VPC CIDR block               | string       | n/a        |
| public_subnet_ids        | Public subnet IDs            | list(string) | n/a        |
| private_app_subnet_ids   | App subnet IDs               | list(string) | n/a        |
| private_db_subnet_ids    | DB subnet IDs                | list(string) | n/a        |

## Outputs

| Name                | Description                  |
|---------------------|------------------------------|
| public_nacl_id      | ID of the public NACL        |
| private_app_nacl_id | ID of the app tier NACL      |
| private_db_nacl_id  | ID of the DB tier NACL       |
