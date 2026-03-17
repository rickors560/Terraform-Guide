# Cognito Component

This component creates a Cognito User Pool with email-based sign-in, password policy, optional MFA (TOTP), advanced security, device tracking, custom attributes, account recovery, Lambda triggers, a Hosted UI domain, web and server app clients, a resource server with API scopes, user groups (admin/editor/viewer) with IAM role mapping, and an Identity Pool with role-based access control.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                     | Description                  | Type         | Default    |
|--------------------------|------------------------------|--------------|------------|
| project_name             | Project name for naming      | string       | n/a        |
| environment              | Environment name             | string       | n/a        |
| password_minimum_length  | Min password length          | number       | 12         |
| mfa_configuration        | OFF, ON, or OPTIONAL         | string       | OPTIONAL   |
| callback_urls            | OAuth callback URLs          | list(string) | [localhost]|
| logout_urls              | OAuth logout URLs            | list(string) | [localhost]|

## Outputs

| Name               | Description                    |
|--------------------|--------------------------------|
| user_pool_id       | ID of the User Pool            |
| user_pool_endpoint | Endpoint of the User Pool      |
| web_client_id      | ID of the web app client       |
| identity_pool_id   | ID of the Identity Pool        |
| hosted_ui_url      | URL of the Hosted UI           |
