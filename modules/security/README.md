# Security Modules

Terraform modules for managing AWS security resources including IAM, encryption, certificate management, secrets, and web application firewalls.

## Sub-Modules

| Module | Description |
|--------|-------------|
| [iam-role](./iam-role/) | IAM roles with configurable trust relationships, policy attachments, and instance profiles |
| [iam-policy](./iam-policy/) | IAM policies with structured policy statement objects |
| [kms](./kms/) | KMS keys with key policies, aliases, rotation, and grants |
| [secrets-manager](./secrets-manager/) | Secrets Manager secrets with rotation, KMS encryption, and replication |
| [acm](./acm/) | ACM certificates with DNS validation via Route53 |
| [waf](./waf/) | WAF v2 Web ACLs with rate limiting, IP blocking, and managed rule groups |

## How They Relate

```
iam-policy --> iam-role (policies attach to roles)
                  |
kms ------------> secrets-manager (KMS encrypts secrets)
  |
  +-------------> acm (KMS can encrypt private keys)

waf ------------> ALB / CloudFront (protects web endpoints)
```

- **iam-policy** and **iam-role** work together -- create policies, then attach them to roles.
- **kms** provides encryption keys used by **secrets-manager**, RDS, S3, EBS, and other services.
- **secrets-manager** stores sensitive values (database passwords, API keys) encrypted with KMS.
- **acm** provisions TLS certificates validated through Route53 DNS records.
- **waf** protects ALB and CloudFront distributions from common web exploits.

## Usage Example

```hcl
module "kms_key" {
  source = "../../modules/security/kms"

  project     = "myapp"
  environment = "prod"
  alias_suffix = "general"

  enable_key_rotation = true

  team        = "platform"
  cost_center = "CC-1234"
}

module "db_secret" {
  source = "../../modules/security/secrets-manager"

  project     = "myapp"
  environment = "prod"
  name_suffix = "db-password"

  kms_key_id = module.kms_key.key_id

  team = "platform"
}

module "app_role" {
  source = "../../modules/security/iam-role"

  project     = "myapp"
  environment = "prod"
  role_suffix = "app"

  trust_policy = {
    principals = [{ type = "Service", identifiers = ["ec2.amazonaws.com"] }]
  }

  managed_policy_arns = [module.app_policy.policy_arn]

  team = "platform"
}

module "app_policy" {
  source = "../../modules/security/iam-policy"

  project     = "myapp"
  environment = "prod"
  name_suffix = "app"

  statements = [
    {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.db_secret.secret_arn]
    }
  ]

  team = "platform"
}

module "cert" {
  source = "../../modules/security/acm"

  project     = "myapp"
  environment = "prod"
  domain_name = "app.example.com"
  zone_id     = "Z0123456789"

  team = "platform"
}
```
