# EBS Component

This component creates encrypted EBS volumes (app data and logs) with KMS, optional instance attachment, an initial snapshot, a DLM lifecycle policy with daily and weekly snapshot schedules, and enables EBS encryption by default for the account with the custom KMS key.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                     | Description                    | Type   | Default     |
|--------------------------|--------------------------------|--------|-------------|
| project_name             | Project name for naming        | string | n/a         |
| environment              | Environment name               | string | n/a         |
| availability_zone        | AZ for volumes                 | string | ap-south-1a |
| ec2_instance_id          | Instance to attach to          | string | ""          |
| app_data_volume_size     | App data volume size (GiB)     | number | 50          |
| app_data_volume_type     | App data volume type           | string | gp3         |
| snapshot_retain_count    | Daily snapshots to retain      | number | 7           |

## Outputs

| Name                    | Description                 |
|-------------------------|-----------------------------|
| app_data_volume_id      | ID of the app data volume   |
| logs_volume_id          | ID of the logs volume       |
| dlm_lifecycle_policy_id | ID of the DLM policy        |
| kms_key_arn             | ARN of the encryption key   |
