###############################################################################
# NLB Component — Network Load Balancer with TCP Listener, Health Checks
###############################################################################

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/nlb/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "nlb"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Network Load Balancer
# -----------------------------------------------------------------------------

resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-nlb"
  internal           = var.internal
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_deletion_protection       = var.environment == "prod"

  tags = {
    Name = "${var.project_name}-${var.environment}-nlb"
  }
}

# -----------------------------------------------------------------------------
# Target Group — TCP
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "tcp" {
  name        = "${var.project_name}-${var.environment}-nlb-tcp-tg"
  port        = var.target_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = var.target_type

  deregistration_delay               = var.deregistration_delay
  connection_termination             = var.connection_termination
  preserve_client_ip                 = var.preserve_client_ip
  proxy_protocol_v2                  = var.proxy_protocol_v2

  health_check {
    enabled             = true
    protocol            = var.health_check_protocol
    port                = var.health_check_port
    path                = var.health_check_protocol == "HTTP" || var.health_check_protocol == "HTTPS" ? var.health_check_path : null
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
  }

  stickiness {
    enabled = var.stickiness_enabled
    type    = "source_ip"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-nlb-tcp-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# TCP Listener
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.listener_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tcp.arn
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tcp-listener"
  }
}

# -----------------------------------------------------------------------------
# TLS Listener (optional)
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "tls" {
  count = var.acm_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = var.tls_listener_port
  protocol          = "TLS"
  certificate_arn   = var.acm_certificate_arn
  ssl_policy        = var.ssl_policy
  alpn_policy       = var.alpn_policy

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tcp.arn
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tls-listener"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project_name}-${var.environment}-nlb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "NLB has unhealthy targets"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.tcp.arn_suffix
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-nlb-unhealthy-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "active_flows" {
  alarm_name          = "${var.project_name}-${var.environment}-nlb-active-flows-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ActiveFlowCount"
  namespace           = "AWS/NetworkELB"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_active_flows_threshold
  alarm_description   = "NLB active flow count exceeding threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-nlb-flows-alarm"
  }
}
