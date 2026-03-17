provider "aws" {
  region = var.aws_region
}

module "waf" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "web-waf"
  description = "WAF for web application"
  scope       = "REGIONAL"

  default_action = "allow"

  enable_rate_limit_rule = true
  rate_limit             = 2000
  rate_limit_priority    = 1

  enable_ip_block_rule = true
  blocked_ip_addresses = ["198.51.100.0/24", "203.0.113.0/24"]
  ip_block_priority    = 0

  managed_rule_groups = [
    {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
      excluded_rules = ["SizeRestrictions_BODY"]
    },
    {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 20
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 30
    },
    {
      name     = "AWSManagedRulesLinuxRuleSet"
      priority = 40
    },
  ]

  resource_arns = var.alb_arns

  team        = var.team
  cost_center = var.cost_center
}
