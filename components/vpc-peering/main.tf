# -----------------------------------------------------------------------------
# VPC Peering Component - Peering, Routes, Security Groups, Cross-Account
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
  #   key            = "components/vpc-peering/terraform.tfstate"
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
      Component   = "vpc-peering"
    }
  }
}

# For cross-account peering, configure this provider with the peer account credentials
provider "aws" {
  alias  = "peer"
  region = var.peer_region != "" ? var.peer_region : var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "vpc-peering"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# VPC Peering Connection
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "main" {
  vpc_id        = var.requester_vpc_id
  peer_vpc_id   = var.accepter_vpc_id
  peer_owner_id = var.peer_account_id != "" ? var.peer_account_id : local.account_id
  peer_region   = var.peer_region != "" ? var.peer_region : var.region
  auto_accept   = var.peer_account_id == "" && var.peer_region == "" ? true : false

  tags = {
    Name = "${local.name_prefix}-peering"
    Side = "requester"
  }
}

# For same-account, same-region: auto_accept works
# For cross-account or cross-region: need explicit accepter
resource "aws_vpc_peering_connection_accepter" "peer" {
  count = var.peer_account_id != "" || var.peer_region != "" ? 1 : 0

  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  auto_accept               = true

  tags = {
    Name = "${local.name_prefix}-peering"
    Side = "accepter"
  }
}

# -----------------------------------------------------------------------------
# Peering Connection Options
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection_options" "requester" {
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [aws_vpc_peering_connection_accepter.peer]
}

resource "aws_vpc_peering_connection_options" "accepter" {
  count = var.peer_account_id != "" || var.peer_region != "" ? 1 : 0

  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [aws_vpc_peering_connection_accepter.peer]
}

# -----------------------------------------------------------------------------
# Route Table Entries - Requester Side
# -----------------------------------------------------------------------------

resource "aws_route" "requester_to_accepter" {
  for_each = toset(var.requester_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

# -----------------------------------------------------------------------------
# Route Table Entries - Accepter Side
# -----------------------------------------------------------------------------

resource "aws_route" "accepter_to_requester" {
  for_each = toset(var.accepter_route_table_ids)

  provider                  = aws.peer
  route_table_id            = each.value
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

# -----------------------------------------------------------------------------
# Security Group Rules - Requester Side
# -----------------------------------------------------------------------------

resource "aws_security_group_rule" "requester_ingress_from_accepter" {
  for_each = var.requester_security_group_ids

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = [var.accepter_vpc_cidr]
  security_group_id = each.value.security_group_id
  description       = "Allow traffic from peered VPC (${var.accepter_vpc_cidr})"
}

# -----------------------------------------------------------------------------
# Security Group Rules - Accepter Side
# -----------------------------------------------------------------------------

resource "aws_security_group_rule" "accepter_ingress_from_requester" {
  for_each = var.accepter_security_group_ids

  provider          = aws.peer
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = [var.requester_vpc_cidr]
  security_group_id = each.value.security_group_id
  description       = "Allow traffic from peered VPC (${var.requester_vpc_cidr})"
}
