# IAM Role Module

Production-grade AWS IAM Role module with configurable trust relationships, policy attachments, and instance profiles.

## Features

- Configurable trust relationships (service, account, OIDC)
- Custom assume role policy override
- Managed policy attachments
- Inline policy support
- Optional instance profile
- Permissions boundary support
- Configurable max session duration and path

## Usage

```hcl
module "ecs_task_role" {
  source = "../../modules/security/iam-role"

  project     = "myapp"
  environment = "prod"
  name        = "ecs-task"
  description = "ECS task execution role"

  trusted_services = ["ecs-tasks.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]

  inline_policies = {
    secrets = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = ["arn:aws:secretsmanager:*:*:secret:myapp/*"]
      }]
    })
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| name | Role name suffix | string | - | yes |
| trusted_services | Service principals | list(string) | [] | no |
| trusted_account_ids | Account IDs | list(string) | [] | no |
| managed_policy_arns | Managed policy ARNs | list(string) | [] | no |
| inline_policies | Inline policies map | map(string) | {} | no |
| create_instance_profile | Create instance profile | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | IAM role ARN |
| role_name | IAM role name |
| instance_profile_arn | Instance profile ARN |
