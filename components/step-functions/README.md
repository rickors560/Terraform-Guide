# Step Functions Component

This component creates a Step Functions state machine implementing an order processing workflow with four Lambda tasks (validate order, process payment, update inventory, send notification), parallel post-payment execution, retry/catch error handling, CloudWatch logging, and X-Ray tracing.

## Workflow

1. **ValidateOrder** - Validates order ID, items, and customer ID
2. **ProcessPayment** - Processes payment and generates a transaction ID
3. **ParallelPostPayment** - Runs inventory update and customer notification in parallel
4. **WaitForShipping** - Simulates shipping preparation wait
5. **OrderComplete** - Success state

Error paths: PaymentFailed and OrderFailed with proper error codes.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name               | Description               | Type   | Default |
|--------------------|---------------------------|--------|---------|
| project_name       | Project name for naming   | string | n/a     |
| environment        | Environment name          | string | n/a     |
| log_retention_days | Log retention period      | number | 30      |

## Outputs

| Name               | Description                    |
|--------------------|--------------------------------|
| state_machine_arn  | ARN of the state machine       |
| execution_role_arn | ARN of the execution role      |
| log_group_name     | CloudWatch log group name      |
