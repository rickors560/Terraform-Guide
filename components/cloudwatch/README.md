# CloudWatch Component

This component creates a comprehensive CloudWatch monitoring setup including a multi-widget dashboard, log groups with metric filters (error, warning, HTTP 5xx/4xx, high latency), metric alarms for CPU, memory, disk, error rate and HTTP 5xx counts, and a composite alarm combining CPU and error rate conditions.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                   | Description                      | Type         | Default |
|------------------------|----------------------------------|--------------|---------|
| project_name           | Project name for naming          | string       | n/a     |
| environment            | Environment name                 | string       | n/a     |
| log_retention_days     | Log retention period             | number       | 30      |
| cpu_threshold_high     | CPU warning threshold            | number       | 75      |
| cpu_threshold_critical | CPU critical threshold           | number       | 90      |
| memory_threshold       | Memory threshold                 | number       | 85      |
| disk_threshold         | Disk threshold                   | number       | 85      |
| alarm_sns_topic_arns   | SNS topics for notifications     | list(string) | []      |

## Outputs

| Name                        | Description                    |
|-----------------------------|--------------------------------|
| application_log_group_name  | Application log group name     |
| dashboard_name              | CloudWatch dashboard name      |
| composite_alarm_arn         | System health composite alarm  |
