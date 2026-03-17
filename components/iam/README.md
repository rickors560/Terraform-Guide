# IAM Component

This component provisions a comprehensive AWS IAM setup following least-privilege principles, including groups (admin, developer, readonly), custom policies (MFA enforcement, IAM admin denial, S3 read-only), IAM users with group membership, an EC2 instance profile with SSM/CloudWatch access, a Lambda execution role, a cross-account assume role, and an OIDC provider for GitHub Actions CI/CD.

## Architecture

- **Groups**: Admin (full access + MFA), Developer (power user minus IAM + MFA), Readonly (read-only + MFA)
- **Password Policy**: 14-char minimum, complexity requirements, 90-day rotation, 24-generation reuse prevention
- **EC2 Instance Profile**: SSM Session Manager, CloudWatch Logs, SSM Parameter Store read access
- **Lambda Role**: CloudWatch Logs write, X-Ray tracing
- **Cross-Account Role**: MFA-protected, 1-hour session, read-only access
- **GitHub OIDC**: Federated identity for GitHub Actions with ECR, S3, and Terraform state access

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.9.0 |
| aws       | ~> 5.0   |

## Inputs

| Name                  | Description                                  | Type         | Default       |
|-----------------------|----------------------------------------------|--------------|---------------|
| region                | AWS region                                   | string       | `ap-south-1`  |
| project_name          | Project name for naming and tagging          | string       | n/a           |
| environment           | Environment (dev, staging, production)       | string       | n/a           |
| iam_users             | Map of users with department and group       | map(object)  | `{}`          |
| trusted_account_ids   | Account IDs for cross-account access         | list(string) | `[]`          |
| enable_github_oidc    | Enable GitHub OIDC provider                  | bool         | `false`       |
| github_repositories   | GitHub repos for OIDC (org/repo format)      | list(string) | `[]`          |

## Outputs

| Name                       | Description                          |
|----------------------------|--------------------------------------|
| admin_group_arn             | ARN of the admin group              |
| developers_group_arn        | ARN of the developers group         |
| readonly_group_arn          | ARN of the readonly group           |
| ec2_instance_profile_arn    | ARN of the EC2 instance profile     |
| lambda_execution_role_arn   | ARN of the Lambda execution role    |
| github_actions_role_arn     | ARN of the GitHub Actions role      |
