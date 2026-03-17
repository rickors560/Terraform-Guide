###############################################################################
# Application Load Balancer
###############################################################################

resource "aws_lb" "this" {
  name               = "${local.name_prefix}-${var.name}"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  enable_http2               = var.enable_http2
  drop_invalid_header_fields = var.drop_invalid_header_fields

  dynamic "access_logs" {
    for_each = var.access_logs_enabled ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.name}"
  })
}

###############################################################################
# Default Target Group
###############################################################################

resource "aws_lb_target_group" "this" {
  name                 = "${local.name_prefix}-${var.target_group_name}"
  port                 = var.target_group_port
  protocol             = var.target_group_protocol
  vpc_id               = var.vpc_id
  target_type          = var.target_type
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = var.health_check.enabled
    path                = var.health_check.path
    port                = var.health_check.port
    protocol            = var.health_check.protocol
    healthy_threshold   = var.health_check.healthy_threshold
    unhealthy_threshold = var.health_check.unhealthy_threshold
    timeout             = var.health_check.timeout
    interval            = var.health_check.interval
    matcher             = var.health_check.matcher
  }

  stickiness {
    enabled         = var.stickiness.enabled
    type            = var.stickiness.type
    cookie_duration = var.stickiness.cookie_duration
    cookie_name     = var.stickiness.cookie_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.target_group_name}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# HTTP Listener
###############################################################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.http_default_action_type == "forward" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }

  dynamic "default_action" {
    for_each = var.http_default_action_type == "redirect" && var.enable_https_listener ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.http_default_action_type == "fixed-response" ? [1] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = var.fixed_response_content_type
        message_body = var.fixed_response_message_body
        status_code  = var.fixed_response_status_code
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-http-listener"
  })
}

###############################################################################
# HTTPS Listener (optional)
###############################################################################

resource "aws_lb_listener" "https" {
  count = var.enable_https_listener ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.ssl_certificate_arn

  dynamic "default_action" {
    for_each = var.https_default_action_type == "forward" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
  }

  dynamic "default_action" {
    for_each = var.https_default_action_type == "fixed-response" ? [1] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = var.fixed_response_content_type
        message_body = var.fixed_response_message_body
        status_code  = var.fixed_response_status_code
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-https-listener"
  })
}
