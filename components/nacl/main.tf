# -----------------------------------------------------------------------------
# NACL Component - Network ACLs for Public/Private Subnets
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
  #   key            = "components/nacl/terraform.tfstate"
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
      Component   = "nacl"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# Public Subnet NACL
# -----------------------------------------------------------------------------

resource "aws_network_acl" "public" {
  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids

  tags = {
    Name = "${local.name_prefix}-public-nacl"
    Tier = "public"
  }
}

# --- Inbound Rules ---

# Allow HTTP from anywhere
resource "aws_network_acl_rule" "public_ingress_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Allow HTTPS from anywhere
resource "aws_network_acl_rule" "public_ingress_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Allow SSH from specified CIDR
resource "aws_network_acl_rule" "public_ingress_ssh" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.ssh_allowed_cidr
  from_port      = 22
  to_port        = 22
}

# Allow ephemeral ports (return traffic from internet)
resource "aws_network_acl_rule" "public_ingress_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow ICMP from VPC
resource "aws_network_acl_rule" "public_ingress_icmp" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 140
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 0
  to_port        = 0
  icmp_type      = -1
  icmp_code      = -1
}

# Allow traffic from private subnets
resource "aws_network_acl_rule" "public_ingress_from_private" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 150
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 0
  to_port        = 0
}

# Deny all other inbound (explicit deny for clarity)
resource "aws_network_acl_rule" "public_ingress_deny_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 32766
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# --- Outbound Rules ---

# Allow HTTP outbound
resource "aws_network_acl_rule" "public_egress_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Allow HTTPS outbound
resource "aws_network_acl_rule" "public_egress_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Allow ephemeral ports outbound (response to inbound requests)
resource "aws_network_acl_rule" "public_egress_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow SSH outbound to VPC (bastion to private instances)
resource "aws_network_acl_rule" "public_egress_ssh" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 130
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 22
  to_port        = 22
}

# Allow ICMP outbound to VPC
resource "aws_network_acl_rule" "public_egress_icmp" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 140
  egress         = true
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 0
  to_port        = 0
  icmp_type      = -1
  icmp_code      = -1
}

# Deny all other outbound
resource "aws_network_acl_rule" "public_egress_deny_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 32766
  egress         = true
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# -----------------------------------------------------------------------------
# Private Subnet NACL (Application Tier)
# -----------------------------------------------------------------------------

resource "aws_network_acl" "private_app" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_app_subnet_ids

  tags = {
    Name = "${local.name_prefix}-private-app-nacl"
    Tier = "private-app"
  }
}

# --- Inbound Rules ---

# Allow traffic from public subnets (ALB to app)
resource "aws_network_acl_rule" "private_app_ingress_from_public" {
  count = length(var.public_subnet_cidrs)

  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 100 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.public_subnet_cidrs[count.index]
  from_port      = var.app_port
  to_port        = var.app_port
}

# Allow ephemeral ports from anywhere (return traffic from internet via NAT)
resource "aws_network_acl_rule" "private_app_ingress_ephemeral" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Allow SSH from public subnets (bastion)
resource "aws_network_acl_rule" "private_app_ingress_ssh" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 210
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 22
  to_port        = 22
}

# Allow ICMP from VPC
resource "aws_network_acl_rule" "private_app_ingress_icmp" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 220
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 0
  to_port        = 0
  icmp_type      = -1
  icmp_code      = -1
}

# Deny all other inbound
resource "aws_network_acl_rule" "private_app_ingress_deny_all" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 32766
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# --- Outbound Rules ---

# Allow HTTPS outbound (AWS APIs, package repos)
resource "aws_network_acl_rule" "private_app_egress_https" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Allow HTTP outbound
resource "aws_network_acl_rule" "private_app_egress_http" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Allow database connections to private DB subnets
resource "aws_network_acl_rule" "private_app_egress_db" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 120
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = var.db_port
  to_port        = var.db_port
}

# Allow cache connections
resource "aws_network_acl_rule" "private_app_egress_cache" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 130
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = var.cache_port
  to_port        = var.cache_port
}

# Allow ephemeral ports (response to ALB, bastion)
resource "aws_network_acl_rule" "private_app_egress_ephemeral" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 140
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Deny all other outbound
resource "aws_network_acl_rule" "private_app_egress_deny_all" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 32766
  egress         = true
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# -----------------------------------------------------------------------------
# Private Subnet NACL (Database Tier)
# -----------------------------------------------------------------------------

resource "aws_network_acl" "private_db" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name = "${local.name_prefix}-private-db-nacl"
    Tier = "private-db"
  }
}

# --- Inbound Rules ---

# Allow database connections from app subnets
resource "aws_network_acl_rule" "private_db_ingress_from_app" {
  count = length(var.private_app_subnet_cidrs)

  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 100 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_app_subnet_cidrs[count.index]
  from_port      = var.db_port
  to_port        = var.db_port
}

# Allow ephemeral ports (return traffic)
resource "aws_network_acl_rule" "private_db_ingress_ephemeral" {
  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# Deny all other inbound
resource "aws_network_acl_rule" "private_db_ingress_deny_all" {
  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 32766
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# --- Outbound Rules ---

# Allow ephemeral ports back to app subnets (response to DB queries)
resource "aws_network_acl_rule" "private_db_egress_ephemeral" {
  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 1024
  to_port        = 65535
}

# Allow DB replication within DB subnets
resource "aws_network_acl_rule" "private_db_egress_replication" {
  count = length(var.private_db_subnet_cidrs)

  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 110 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.private_db_subnet_cidrs[count.index]
  from_port      = var.db_port
  to_port        = var.db_port
}

# Allow HTTPS for AWS API calls (RDS monitoring, snapshots)
resource "aws_network_acl_rule" "private_db_egress_https" {
  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Deny all other outbound
resource "aws_network_acl_rule" "private_db_egress_deny_all" {
  network_acl_id = aws_network_acl.private_db.id
  rule_number    = 32766
  egress         = true
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
