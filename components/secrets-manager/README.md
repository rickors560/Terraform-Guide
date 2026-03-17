# Secrets Manager Component

This component provisions AWS Secrets Manager secrets for database credentials, API keys, and application configuration, each encrypted with a dedicated KMS key. Includes resource policies for cross-account access, rotation IAM role setup, and secret versioning.

## Architecture

- **KMS Key**: Dedicated encryption key with Secrets Manager service access
- **Database Secret**: Structured JSON with host, port, username, password, engine, dbname
- **API Key Secret**: API key and secret pair
- **App Config Secret**: JWT secret, encryption key, session secret
- **Resource Policy**: Cross-account access with environment tag condition
- **Rotation Role**: IAM role for Lambda-based rotation (optional)

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Update secret values before applying
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                    | Description                            | Type         | Default |
|-------------------------|----------------------------------------|--------------|---------|
| project_name            | Project name for naming                | string       | n/a     |
| environment             | Environment name                       | string       | n/a     |
| recovery_window_in_days | Days before permanent deletion         | number       | 30      |
| enable_rotation         | Enable automatic rotation              | bool         | false   |
| cross_account_ids       | Account IDs for cross-account access   | list(string) | []      |

## Outputs

| Name                | Description                          |
|---------------------|--------------------------------------|
| database_secret_arn | ARN of the database secret           |
| api_key_secret_arn  | ARN of the API key secret            |
| app_config_secret_arn | ARN of the app config secret       |
| kms_key_arn         | ARN of the encryption KMS key        |
