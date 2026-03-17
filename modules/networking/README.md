# Networking Modules

Terraform modules for provisioning and managing AWS networking infrastructure including VPCs, load balancers, DNS, CDN, and security groups.

## Sub-Modules

| Module | Description |
|--------|-------------|
| [vpc](./vpc/) | Production-grade VPC with public, private, and database subnets, NAT gateways, and flow logs |
| [security-groups](./security-groups/) | Flexible security groups with ingress/egress rules supporting CIDR blocks, SG references, and self-referencing rules |
| [alb](./alb/) | Application Load Balancer with HTTP/HTTPS listeners, target groups, and access logging |
| [nlb](./nlb/) | Network Load Balancer with TCP/TLS listeners and target groups |
| [cloudfront](./cloudfront/) | CloudFront distribution with S3 OAC, custom origins, caching, and WAF integration |
| [route53](./route53/) | Route53 hosted zones, DNS records, and health checks with routing policy support |

## How They Relate

The networking modules form a layered stack:

```
route53 (DNS)
    |
    v
cloudfront (CDN) ---> alb / nlb (Load Balancers)
                          |
                          v
                    security-groups
                          |
                          v
                        vpc (Foundation)
```

- **vpc** is the foundation -- all other networking resources deploy into VPC subnets.
- **security-groups** control traffic flow to/from resources within the VPC.
- **alb** and **nlb** sit in public or private subnets and route traffic to backend targets.
- **cloudfront** distributes content globally and can use ALB/NLB as origins.
- **route53** provides DNS resolution, pointing domain names to CloudFront, ALB, or NLB endpoints.

## Usage Example

```hcl
module "vpc" {
  source = "../../modules/networking/vpc"

  project     = "myapp"
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  enable_nat_gateway = true
  single_nat_gateway = false
  enable_flow_logs   = true

  team        = "platform"
  cost_center = "CC-1234"
}

module "alb_sg" {
  source = "../../modules/networking/security-groups"

  project     = "myapp"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id
  name_suffix = "alb"

  ingress_rules = [
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }
  ]

  team = "platform"
}

module "alb" {
  source = "../../modules/networking/alb"

  project     = "myapp"
  environment = "prod"

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]

  team = "platform"
}

module "dns" {
  source = "../../modules/networking/route53"

  project     = "myapp"
  environment = "prod"
  domain_name = "example.com"

  records = [
    {
      name    = "app"
      type    = "A"
      alias   = {
        name                   = module.alb.dns_name
        zone_id                = module.alb.zone_id
        evaluate_target_health = true
      }
    }
  ]

  team = "platform"
}
```
