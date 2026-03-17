# Security Groups Component

This component creates a multi-tier security group architecture: ALB (public HTTP/HTTPS), application (ALB-sourced traffic, self-referencing for clustering), database (app-sourced only, self-referencing for replication, restricted egress), cache (app-sourced, self-referencing), and an optional bastion with SSH and targeted egress. All rules use security group references instead of CIDRs where possible.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                      | Description                  | Type         | Default |
|---------------------------|------------------------------|--------------|---------|
| project_name              | Project name for naming      | string       | n/a     |
| environment               | Environment name             | string       | n/a     |
| vpc_id                    | VPC ID                       | string       | n/a     |
| app_port                  | Application port             | number       | 8080    |
| db_port                   | Database port                | number       | 5432    |
| cache_port                | Cache port                   | number       | 6379    |
| create_bastion_sg         | Create bastion SG            | bool         | false   |

## Outputs

| Name                    | Description                    |
|-------------------------|--------------------------------|
| alb_security_group_id   | ALB security group ID          |
| app_security_group_id   | Application security group ID  |
| db_security_group_id    | Database security group ID     |
| cache_security_group_id | Cache security group ID        |
