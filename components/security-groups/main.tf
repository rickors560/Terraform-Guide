# -----------------------------------------------------------------------------
# Security Groups Component - Web, App, DB Tiers with Inter-Group References
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/security-groups/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "security-groups"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# ALB / Web Tier Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
    Tier = "web"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet"
}

resource "aws_security_group_rule" "alb_egress_to_app" {
  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow traffic to application tier"
}

# -----------------------------------------------------------------------------
# Application Tier Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Security group for Application tier instances"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-app-sg"
    Tier = "app"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "app_ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow traffic from ALB"
}

resource "aws_security_group_rule" "app_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.app.id
  description       = "Allow intra-tier communication"
}

resource "aws_security_group_rule" "app_ingress_ssh" {
  count = var.bastion_security_group_id != "" ? 1 : 0

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.bastion_security_group_id
  security_group_id        = aws_security_group.app.id
  description              = "Allow SSH from bastion"
}

resource "aws_security_group_rule" "app_egress_to_db" {
  type                     = "egress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow traffic to database tier"
}

resource "aws_security_group_rule" "app_egress_to_cache" {
  type                     = "egress"
  from_port                = var.cache_port
  to_port                  = var.cache_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cache.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow traffic to cache tier"
}

resource "aws_security_group_rule" "app_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  description       = "Allow HTTPS outbound (AWS APIs, external services)"
}

resource "aws_security_group_rule" "app_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  description       = "Allow HTTP outbound (package repos)"
}

# -----------------------------------------------------------------------------
# Database Tier Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "Security group for Database tier (RDS/Aurora)"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-db-sg"
    Tier = "db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "db_ingress_from_app" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
  description              = "Allow database connections from application tier"
}

resource "aws_security_group_rule" "db_ingress_self" {
  type              = "ingress"
  from_port         = var.db_port
  to_port           = var.db_port
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.db.id
  description       = "Allow replication between database instances"
}

resource "aws_security_group_rule" "db_ingress_from_bastion" {
  count = var.bastion_security_group_id != "" ? 1 : 0

  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.bastion_security_group_id
  security_group_id        = aws_security_group.db.id
  description              = "Allow database connections from bastion"
}

resource "aws_security_group_rule" "db_egress_none" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = []
  self              = true
  security_group_id = aws_security_group.db.id
  description       = "Restrict outbound to self only (replication)"
}

# -----------------------------------------------------------------------------
# Cache Tier Security Group (Redis / ElastiCache)
# -----------------------------------------------------------------------------

resource "aws_security_group" "cache" {
  name        = "${local.name_prefix}-cache-sg"
  description = "Security group for Cache tier (ElastiCache)"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-cache-sg"
    Tier = "cache"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cache_ingress_from_app" {
  type                     = "ingress"
  from_port                = var.cache_port
  to_port                  = var.cache_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.cache.id
  description              = "Allow cache connections from application tier"
}

resource "aws_security_group_rule" "cache_ingress_self" {
  type              = "ingress"
  from_port         = var.cache_port
  to_port           = var.cache_port
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.cache.id
  description       = "Allow replication between cache nodes"
}

resource "aws_security_group_rule" "cache_egress_self" {
  type              = "egress"
  from_port         = var.cache_port
  to_port           = var.cache_port
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.cache.id
  description       = "Allow outbound to self for replication"
}

# -----------------------------------------------------------------------------
# Bastion Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "bastion" {
  count = var.create_bastion_sg ? 1 : 0

  name        = "${local.name_prefix}-bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-bastion-sg"
    Tier = "bastion"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "bastion_ingress_ssh" {
  count = var.create_bastion_sg ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_allowed_cidrs
  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow SSH from trusted networks"
}

resource "aws_security_group_rule" "bastion_egress_ssh_app" {
  count = var.create_bastion_sg ? 1 : 0

  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.bastion[0].id
  description              = "Allow SSH to application tier"
}

resource "aws_security_group_rule" "bastion_egress_db" {
  count = var.create_bastion_sg ? 1 : 0

  type                     = "egress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  security_group_id        = aws_security_group.bastion[0].id
  description              = "Allow database access from bastion"
}

resource "aws_security_group_rule" "bastion_egress_https" {
  count = var.create_bastion_sg ? 1 : 0

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow HTTPS outbound"
}
