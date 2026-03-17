###############################################################################
# Route53 Hosted Zone
###############################################################################

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name          = var.zone_name
  force_destroy = var.force_destroy

  dynamic "vpc" {
    for_each = var.private_zone && var.vpc_id != null ? [1] : []
    content {
      vpc_id = var.vpc_id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.zone_name}"
  })
}

###############################################################################
# DNS Records
###############################################################################

resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = local.zone_id
  name    = each.key
  type    = each.value.type

  ttl     = each.value.alias == null ? each.value.ttl : null
  records = each.value.alias == null ? each.value.records : null

  set_identifier = each.value.set_identifier

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  dynamic "weighted_routing_policy" {
    for_each = each.value.weighted_routing != null ? [each.value.weighted_routing] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  dynamic "latency_routing_policy" {
    for_each = each.value.latency_routing != null ? [each.value.latency_routing] : []
    content {
      region = latency_routing_policy.value.region
    }
  }

  dynamic "failover_routing_policy" {
    for_each = each.value.failover_routing != null ? [each.value.failover_routing] : []
    content {
      type = failover_routing_policy.value.type
    }
  }

  health_check_id = each.value.health_check_id
}

###############################################################################
# Health Checks
###############################################################################

resource "aws_route53_health_check" "this" {
  for_each = var.health_checks

  type                            = each.value.type
  fqdn                            = each.value.fqdn
  ip_address                      = each.value.ip_address
  port                            = each.value.port
  resource_path                   = each.value.resource_path
  failure_threshold               = each.value.failure_threshold
  request_interval                = each.value.request_interval
  search_string                   = each.value.search_string
  measure_latency                 = each.value.measure_latency
  regions                         = each.value.regions
  enable_sni                      = each.value.enable_sni
  disabled                        = each.value.disabled
  invert_healthcheck              = each.value.invert_healthcheck
  insufficient_data_health_status = each.value.insufficient_data_health_status

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-hc-${each.key}"
  })
}
