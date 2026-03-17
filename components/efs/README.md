# EFS Component

This component creates an EFS file system with KMS encryption, mount targets across specified subnets, three access points (app, logs, shared) with POSIX user mapping, a security group for NFS access, lifecycle policies for IA transition, backup policy, and a file system policy enforcing encryption in transit.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                       | Description                       | Type         | Default        |
|----------------------------|-----------------------------------|--------------|----------------|
| project_name               | Project name for naming           | string       | n/a            |
| environment                | Environment name                  | string       | n/a            |
| vpc_id                     | VPC ID for security group         | string       | n/a            |
| subnet_ids                 | Subnets for mount targets         | list(string) | n/a            |
| performance_mode           | generalPurpose or maxIO           | string       | generalPurpose |
| throughput_mode            | bursting, provisioned, or elastic | string       | elastic        |
| enable_backup              | Enable automatic backups          | bool         | true           |

## Outputs

| Name                 | Description                  |
|----------------------|------------------------------|
| file_system_id       | ID of the EFS file system    |
| file_system_dns_name | DNS name for mounting        |
| app_access_point_id  | ID of the app access point   |
| security_group_id    | ID of the EFS security group |
