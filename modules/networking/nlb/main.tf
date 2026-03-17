###############################################################################
# Network Load Balancer
###############################################################################

resource "aws_lb" "this" {
  name               = "${local.name_prefix}-${var.name}"
  internal           = var.internal
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_deletion_protection       = var.enable_deletion_protection

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.name}"
  })
}

###############################################################################
# Target Groups
###############################################################################

resource "aws_lb_target_group" "this" {
  count = length(var.target_groups)

  name                 = "${local.name_prefix}-${var.target_groups[count.index].name}"
  port                 = var.target_groups[count.index].port
  protocol             = var.target_groups[count.index].protocol
  vpc_id               = var.vpc_id
  target_type          = var.target_groups[count.index].target_type
  deregistration_delay = var.target_groups[count.index].deregistration_delay
  preserve_client_ip   = var.target_groups[count.index].preserve_client_ip
  proxy_protocol_v2    = var.target_groups[count.index].proxy_protocol_v2

  health_check {
    enabled             = var.target_groups[count.index].health_check.enabled
    port                = var.target_groups[count.index].health_check.port
    protocol            = var.target_groups[count.index].health_check.protocol
    path                = var.target_groups[count.index].health_check.protocol == "HTTP" || var.target_groups[count.index].health_check.protocol == "HTTPS" ? var.target_groups[count.index].health_check.path : null
    healthy_threshold   = var.target_groups[count.index].health_check.healthy_threshold
    unhealthy_threshold = var.target_groups[count.index].health_check.unhealthy_threshold
    interval            = var.target_groups[count.index].health_check.interval
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.target_groups[count.index].name}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# Listeners
###############################################################################

resource "aws_lb_listener" "this" {
  count = length(var.listeners)

  load_balancer_arn = aws_lb.this.arn
  port              = var.listeners[count.index].port
  protocol          = var.listeners[count.index].protocol

  certificate_arn = var.listeners[count.index].protocol == "TLS" ? var.listeners[count.index].certificate_arn : null
  ssl_policy      = var.listeners[count.index].protocol == "TLS" ? var.listeners[count.index].ssl_policy : null
  alpn_policy     = var.listeners[count.index].protocol == "TLS" ? var.listeners[count.index].alpn_policy : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.listeners[count.index].target_group_index].arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.name}-listener-${var.listeners[count.index].port}"
  })
}
