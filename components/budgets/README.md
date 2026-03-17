# Budgets Component

This component creates AWS Budgets for cost management: an overall monthly cost budget with threshold notifications at 50%, 80%, 100% actual and 100% forecasted, plus service-specific budgets for EC2, RDS, and data transfer with their own thresholds. All budgets support email and SNS notifications.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                         | Description                  | Type         | Default |
|------------------------------|------------------------------|--------------|---------|
| project_name                 | Project name for naming      | string       | n/a     |
| environment                  | Environment name             | string       | n/a     |
| monthly_budget_amount        | Overall monthly budget (USD) | string       | 1000    |
| ec2_budget_amount            | EC2 monthly budget (USD)     | string       | 500     |
| rds_budget_amount            | RDS monthly budget (USD)     | string       | 300     |
| data_transfer_budget_amount  | Data transfer budget (USD)   | string       | 100     |
| budget_notification_emails   | Emails for notifications     | list(string) | []      |

## Outputs

| Name                    | Description                |
|-------------------------|----------------------------|
| monthly_cost_budget_id  | ID of the monthly budget   |
| ec2_budget_id           | ID of the EC2 budget       |
| rds_budget_id           | ID of the RDS budget       |
| data_transfer_budget_id | ID of the data xfer budget |
