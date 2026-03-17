provider "aws" {
  region = var.aws_region
}

module "web_sg" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "web"
  description = "Security group for web tier"
  vpc_id      = var.vpc_id

  ingress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from anywhere"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from anywhere"
    },
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    },
  ]

  team        = var.team
  cost_center = var.cost_center
}

module "app_sg" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "app"
  description = "Security group for application tier with self-referencing"
  vpc_id      = var.vpc_id

  ingress_rules = [
    {
      from_port         = 8080
      to_port           = 8080
      protocol          = "tcp"
      security_group_id = module.web_sg.security_group_id
      description       = "App port from web tier"
    },
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      self        = true
      description = "Allow all traffic within this security group"
    },
  ]

  team        = var.team
  cost_center = var.cost_center
}
