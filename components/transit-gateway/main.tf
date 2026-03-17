# -----------------------------------------------------------------------------
# Transit Gateway Component - TGW, VPC Attachments, Route Tables, RAM Sharing
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
  #   key            = "components/transit-gateway/terraform.tfstate"
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
      Component   = "transit-gateway"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "current" {
  count = var.share_with_organization ? 1 : 0
}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# Transit Gateway
# -----------------------------------------------------------------------------

resource "aws_ec2_transit_gateway" "main" {
  description = "${local.name_prefix} Transit Gateway"

  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments ? "enable" : "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"
  multicast_support               = "disable"

  tags = {
    Name = "${local.name_prefix}-tgw"
  }
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------

resource "aws_ec2_transit_gateway_route_table" "shared_services" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "${local.name_prefix}-tgw-rt-shared-services"
  }
}

resource "aws_ec2_transit_gateway_route_table" "isolated" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "${local.name_prefix}-tgw-rt-isolated"
  }
}

resource "aws_ec2_transit_gateway_route_table" "egress" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "${local.name_prefix}-tgw-rt-egress"
  }
}

# -----------------------------------------------------------------------------
# VPC Attachments
# -----------------------------------------------------------------------------

resource "aws_ec2_transit_gateway_vpc_attachment" "vpcs" {
  for_each = var.vpc_attachments

  subnet_ids         = each.value.subnet_ids
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = each.value.vpc_id

  dns_support                                    = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "${local.name_prefix}-tgw-attach-${each.key}"
  }
}

# -----------------------------------------------------------------------------
# Route Table Associations
# -----------------------------------------------------------------------------

resource "aws_ec2_transit_gateway_route_table_association" "vpcs" {
  for_each = var.vpc_attachments

  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.vpcs[each.key].id
  transit_gateway_route_table_id = (
    each.value.route_table_type == "shared_services" ? aws_ec2_transit_gateway_route_table.shared_services.id :
    each.value.route_table_type == "egress" ? aws_ec2_transit_gateway_route_table.egress.id :
    aws_ec2_transit_gateway_route_table.isolated.id
  )
}

# -----------------------------------------------------------------------------
# Route Table Propagations
# -----------------------------------------------------------------------------

# Shared services VPCs propagate to all route tables
resource "aws_ec2_transit_gateway_route_table_propagation" "shared_to_isolated" {
  for_each = {
    for k, v in var.vpc_attachments : k => v if v.route_table_type == "shared_services"
  }

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpcs[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.isolated.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared_to_egress" {
  for_each = {
    for k, v in var.vpc_attachments : k => v if v.route_table_type == "shared_services"
  }

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpcs[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

# Isolated VPCs propagate to shared services route table only
resource "aws_ec2_transit_gateway_route_table_propagation" "isolated_to_shared" {
  for_each = {
    for k, v in var.vpc_attachments : k => v if v.route_table_type == "isolated"
  }

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpcs[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services.id
}

# Egress VPC propagates to all route tables
resource "aws_ec2_transit_gateway_route_table_propagation" "egress_to_shared" {
  for_each = {
    for k, v in var.vpc_attachments : k => v if v.route_table_type == "egress"
  }

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpcs[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "egress_to_isolated" {
  for_each = {
    for k, v in var.vpc_attachments : k => v if v.route_table_type == "egress"
  }

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpcs[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.isolated.id
}

# -----------------------------------------------------------------------------
# Static Routes (default route to egress VPC for internet-bound traffic)
# -----------------------------------------------------------------------------

resource "aws_ec2_transit_gateway_route" "default_to_egress" {
  for_each = {
    for k, v in var.vpc_attachments : k => v if v.route_table_type == "egress"
  }

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpcs[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.isolated.id
}

resource "aws_ec2_transit_gateway_route" "default_to_egress_shared" {
  for_each = {
    for k, v in var.vpc_attachments : k => v if v.route_table_type == "egress"
  }

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.vpcs[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services.id
}

# Blackhole route for RFC1918 space to prevent unintended routing
resource "aws_ec2_transit_gateway_route" "blackhole_10" {
  destination_cidr_block         = "10.0.0.0/8"
  blackhole                      = true
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

resource "aws_ec2_transit_gateway_route" "blackhole_172" {
  destination_cidr_block         = "172.16.0.0/12"
  blackhole                      = true
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

resource "aws_ec2_transit_gateway_route" "blackhole_192" {
  destination_cidr_block         = "192.168.0.0/16"
  blackhole                      = true
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

# -----------------------------------------------------------------------------
# RAM Resource Share (for cross-account sharing)
# -----------------------------------------------------------------------------

resource "aws_ram_resource_share" "tgw" {
  count = var.share_with_organization || length(var.share_with_account_ids) > 0 ? 1 : 0

  name                      = "${local.name_prefix}-tgw-share"
  allow_external_principals = !var.share_with_organization

  tags = {
    Name = "${local.name_prefix}-tgw-share"
  }
}

resource "aws_ram_resource_association" "tgw" {
  count = var.share_with_organization || length(var.share_with_account_ids) > 0 ? 1 : 0

  resource_arn       = aws_ec2_transit_gateway.main.arn
  resource_share_arn = aws_ram_resource_share.tgw[0].arn
}

resource "aws_ram_principal_association" "organization" {
  count = var.share_with_organization ? 1 : 0

  principal          = data.aws_organizations_organization.current[0].arn
  resource_share_arn = aws_ram_resource_share.tgw[0].arn
}

resource "aws_ram_principal_association" "accounts" {
  for_each = var.share_with_organization ? toset([]) : toset(var.share_with_account_ids)

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.tgw[0].arn
}
