# WAF Module

Production-grade AWS WAF v2 Web ACL module with rate limiting, IP blocking, and managed rule groups.

## Features

- WAF v2 Web ACL (REGIONAL or CLOUDFRONT scope)
- Rate limiting rule with configurable threshold
- IP set block list rule
- AWS managed rule groups (CommonRuleSet, SQLiRuleSet, KnownBadInputsRuleSet)
- Custom rule support
- CloudWatch metrics and logging
- Resource association for REGIONAL scope
- Sampled requests

## Usage

```hcl
module "waf" {
  source = "../../modules/security/waf"

  project     = "myapp"
  environment = "prod"
  name        = "web-waf"
  scope       = "REGIONAL"

  enable_rate_limit_rule = true
  rate_limit             = 2000

  enable_ip_block_rule = true
  blocked_ip_addresses = ["192.0.2.0/24"]

  managed_rule_groups = [
    {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
    },
    {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 20
    },
  ]

  resource_arns = [module.alb.alb_arn]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| scope | REGIONAL or CLOUDFRONT | string | "REGIONAL" | no |
| rate_limit | Rate limit per 5 min | number | 2000 | no |
| managed_rule_groups | Managed rule groups | list(object) | Common+SQLi+BadInputs | no |
| resource_arns | ARNs to associate | list(string) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| web_acl_id | Web ACL ID |
| web_acl_arn | Web ACL ARN |
| web_acl_capacity | Web ACL capacity units |
| ip_set_arn | IP block list ARN |
