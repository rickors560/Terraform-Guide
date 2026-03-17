# Route53 Module

Production-grade AWS Route53 module for hosted zones, DNS records, and health checks with routing policy support.

## Features

- Public or private hosted zones
- DNS records: A, AAAA, CNAME, MX, TXT, and alias records
- Routing policies: simple, weighted, latency, failover
- Health checks with configurable thresholds
- Use existing zone or create new
- Consistent tagging

## Usage

```hcl
module "dns" {
  source = "../../modules/networking/route53"

  project     = "myapp"
  environment = "prod"
  zone_name   = "example.com"

  records = {
    "app.example.com" = {
      type = "A"
      alias = {
        name    = module.alb.alb_dns_name
        zone_id = module.alb.alb_zone_id
      }
    }
    "mail.example.com" = {
      type    = "MX"
      ttl     = 300
      records = ["10 mail.example.com"]
    }
  }

  health_checks = {
    "app" = {
      fqdn          = "app.example.com"
      resource_path = "/health"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| zone_name | Domain name | string | - | yes |
| records | DNS records map | map(object) | {} | no |
| health_checks | Health checks map | map(object) | {} | no |
| private_zone | Is private zone | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| zone_id | Hosted zone ID |
| name_servers | Name server list |
| record_fqdns | Map of record FQDNs |
| health_check_ids | Map of health check IDs |
