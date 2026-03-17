# Environments

Per-environment root configurations that compose modules and components into complete infrastructure stacks.

## Available Environments

| Environment | Purpose | CIDR Block |
|---|---|---|
| `dev/` | Development and experimentation | `10.0.0.0/16` |
| `staging/` | Pre-production testing and validation | `10.1.0.0/16` |
| `prod/` | Production workloads | `10.2.0.0/16` |

## Structure

Each environment directory contains:

```
environments/{env}/
├── main.tf              # Module composition
├── variables.tf         # Environment-specific variables
├── outputs.tf           # Environment outputs
├── versions.tf          # Terraform and provider constraints
├── providers.tf         # Provider configuration with backend
├── terraform.tfvars     # Variable values (gitignored)
└── README.md            # Environment-specific notes
```

## Backend Configuration

Each environment stores its state in a separate S3 key:

```hcl
terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state"
    key            = "dev/terraform.tfstate"     # Changes per environment
    region         = "ap-south-1"
    dynamodb_table = "myapp-terraform-locks"
    encrypt        = true
  }
}
```

## Usage

```bash
# Using Make (recommended)
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
make destroy ENV=dev

# Direct Terraform
cd environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Environment Differences

| Parameter | Dev | Staging | Prod |
|---|---|---|---|
| Instance sizes | Small (t3.micro/small) | Medium (t3.medium) | Large (m5.large+) |
| Multi-AZ | No | Yes | Yes |
| Read replicas | 0 | 1 | 2 |
| Node count | 1–2 | 2–3 | 3–6 |
| Backup retention | 1 day | 7 days | 30 days |
| Deletion protection | No | Yes | Yes |
