# -----------------------------------------------------------------------------
# NAT Gateway Component - Multi-AZ NAT Gateways with EIPs and Route Tables
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
  #   key            = "components/nat-gateway/terraform.tfstate"
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
      Component   = "nat-gateway"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  az_count    = length(var.public_subnet_ids)
  # For HA, create one NAT GW per AZ; for cost savings, use single NAT GW
  nat_count   = var.high_availability ? local.az_count : 1
}

# -----------------------------------------------------------------------------
# Elastic IP Addresses for NAT Gateways
# -----------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Public NAT Gateways
# -----------------------------------------------------------------------------

resource "aws_nat_gateway" "public" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]

  tags = {
    Name = "${local.name_prefix}-nat-gw-${count.index + 1}"
    AZ   = data.aws_subnet.public[count.index].availability_zone
  }

  depends_on = [aws_eip.nat]
}

data "aws_subnet" "public" {
  count = local.nat_count
  id    = var.public_subnet_ids[count.index]
}

# -----------------------------------------------------------------------------
# Private NAT Gateway (for VPC-to-VPC connectivity without internet)
# -----------------------------------------------------------------------------

resource "aws_nat_gateway" "private" {
  count = var.create_private_nat_gateway ? 1 : 0

  connectivity_type = "private"
  subnet_id         = var.private_nat_subnet_id != "" ? var.private_nat_subnet_id : var.public_subnet_ids[0]

  tags = {
    Name = "${local.name_prefix}-nat-gw-private"
  }
}

# -----------------------------------------------------------------------------
# Route Tables for Private Subnets
# -----------------------------------------------------------------------------

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_ids)
  vpc_id = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-private-rt-${count.index + 1}"
    Tier = "private"
  }
}

# Route to NAT Gateway for internet-bound traffic
resource "aws_route" "private_nat" {
  count = length(var.private_subnet_ids)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public[var.high_availability ? count.index % local.nat_count : 0].id
}

# Associate private subnets with their route tables
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_ids)

  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private[count.index].id
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms for NAT Gateway Monitoring
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "nat_error_port_allocation" {
  count = local.nat_count

  alarm_name          = "${local.name_prefix}-nat-${count.index + 1}-error-port-allocation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ErrorPortAllocation"
  namespace           = "AWS/NATGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "NAT Gateway ${count.index + 1} port allocation errors detected"
  treat_missing_data  = "notBreaching"

  dimensions = {
    NatGatewayId = aws_nat_gateway.public[count.index].id
  }

  alarm_actions = var.alarm_sns_topic_arns

  tags = {
    Name = "${local.name_prefix}-nat-${count.index + 1}-error-port"
  }
}

resource "aws_cloudwatch_metric_alarm" "nat_packets_drop" {
  count = local.nat_count

  alarm_name          = "${local.name_prefix}-nat-${count.index + 1}-packets-drop"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "PacketsDropCount"
  namespace           = "AWS/NATGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "NAT Gateway ${count.index + 1} dropping packets"
  treat_missing_data  = "notBreaching"

  dimensions = {
    NatGatewayId = aws_nat_gateway.public[count.index].id
  }

  alarm_actions = var.alarm_sns_topic_arns

  tags = {
    Name = "${local.name_prefix}-nat-${count.index + 1}-packets-drop"
  }
}

resource "aws_cloudwatch_metric_alarm" "nat_bytes_out" {
  count = local.nat_count

  alarm_name          = "${local.name_prefix}-nat-${count.index + 1}-high-bandwidth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "BytesOutToDestination"
  namespace           = "AWS/NATGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = var.nat_bandwidth_alarm_threshold
  alarm_description   = "NAT Gateway ${count.index + 1} outbound bandwidth unusually high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    NatGatewayId = aws_nat_gateway.public[count.index].id
  }

  alarm_actions = var.alarm_sns_topic_arns

  tags = {
    Name = "${local.name_prefix}-nat-${count.index + 1}-bandwidth"
  }
}
