# SSM Parameter Store Component

This component creates SSM Parameter Store parameters organized in a hierarchical path structure (/{project}/{environment}/...) with three parameter types: String (app config, ports, log levels), StringList (feature flags, CORS origins), and SecureString (database credentials, cache tokens, API keys) encrypted with a dedicated KMS key. Includes IAM policies for full and config-only read access.

## Parameter Hierarchy

```
/{project}/{environment}/
  app/
    name, environment, log-level, port, max-connections
    feature-flags (StringList)
    allowed-origins (StringList)
  database/
    host, port, name
    username (SecureString)
    password (SecureString)
    connection-string (SecureString)
  cache/
    host, port
    auth-token (SecureString)
  external/
    api-base-url
    api-key (SecureString)
```

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Update sensitive values before applying
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                  | Description                  | Type         | Default   |
|-----------------------|------------------------------|--------------|-----------|
| project_name          | Project name for naming      | string       | n/a       |
| environment           | Environment name             | string       | n/a       |
| log_level             | Application log level        | string       | INFO      |
| feature_flags         | Enabled feature flags        | list(string) | [2 flags] |
| db_host               | Database host                | string       | localhost |
| db_password           | Database password            | string       | n/a       |

## Outputs

| Name                       | Description                        |
|----------------------------|------------------------------------|
| parameter_prefix           | Hierarchical path prefix           |
| kms_key_arn                | ARN of the encryption key          |
| ssm_read_all_policy_arn    | IAM policy for full read access    |
| ssm_read_config_policy_arn | IAM policy for config-only access  |
