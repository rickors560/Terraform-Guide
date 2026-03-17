# SES Component

This component configures AWS SES with domain identity verification, DKIM signing, SPF and DMARC DNS records via Route53, a Mail From domain, a configuration set with TLS enforcement and reputation metrics, SNS and CloudWatch event destinations for bounces/complaints/deliveries, and email templates (welcome, password reset, notification) with HTML and plaintext versions.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                   | Description                      | Type   | Default     |
|------------------------|----------------------------------|--------|-------------|
| project_name           | Project name for naming          | string | n/a         |
| environment            | Environment name                 | string | n/a         |
| domain_name            | SES domain identity              | string | n/a         |
| create_route53_records | Create DNS records in Route53    | bool   | false       |
| dmarc_policy           | DMARC policy level               | string | quarantine  |

## Outputs

| Name                   | Description                     |
|------------------------|---------------------------------|
| domain_identity_arn    | ARN of the SES domain identity  |
| configuration_set_name | Name of the config set          |
| ses_events_topic_arn   | ARN of the events SNS topic     |
| dkim_tokens            | DKIM tokens for DNS setup       |
