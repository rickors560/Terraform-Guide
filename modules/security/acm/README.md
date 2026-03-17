# ACM Module

Production-grade AWS ACM certificate module with DNS validation via Route53.

## Features

- ACM certificate request with DNS validation
- Automatic Route53 validation record creation
- Subject alternative names support
- Configurable validation timeout
- Key algorithm selection
- create_before_destroy lifecycle for zero-downtime rotation

## Usage

```hcl
module "acm" {
  source = "../../modules/security/acm"

  project     = "myapp"
  environment = "prod"
  domain_name = "example.com"
  zone_id     = module.route53.zone_id

  subject_alternative_names = [
    "*.example.com",
    "api.example.com",
  ]

  wait_for_validation = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| domain_name | Primary domain name | string | - | yes |
| zone_id | Route53 zone ID | string | - | yes |
| subject_alternative_names | SANs | list(string) | [] | no |
| wait_for_validation | Wait for validation | bool | true | no |
| validation_timeout | Validation timeout | string | "45m" | no |

## Outputs

| Name | Description |
|------|-------------|
| certificate_arn | Certificate ARN |
| validated_certificate_arn | Validated certificate ARN |
| certificate_status | Certificate status |
