locals {
  is_application = var.load_balancer_type == "application"
  is_network     = var.load_balancer_type == "network"
}

# Load Balancer
resource "aws_lb" "this" {
  name                             = var.name
  internal                         = var.internal
  load_balancer_type               = var.load_balancer_type
  security_groups                  = local.is_application ? var.security_groups : null
  subnets                          = var.subnets
  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = local.is_network ? var.enable_cross_zone_load_balancing : null
  customer_owned_ipv4_pool         = var.customer_owned_ipv4_pool
  ip_address_type                  = var.ip_address_type
  desync_mitigation_mode           = local.is_application ? var.desync_mitigation_mode : null

  dynamic "access_logs" {
    for_each = var.access_logs != null ? [var.access_logs] : []
    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = access_logs.value.enabled
    }
  }

  dynamic "subnet_mapping" {
    for_each = var.subnet_mappings
    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = lookup(subnet_mapping.value, "allocation_id", null)
      private_ipv4_address = lookup(subnet_mapping.value, "private_ipv4_address", null)
      ipv6_address         = lookup(subnet_mapping.value, "ipv6_address", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    },
  )
}

# Target Groups
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name                          = lookup(each.value, "name", null)
  name_prefix                   = lookup(each.value, "name_prefix", null)
  port                          = each.value.port
  protocol                      = each.value.protocol
  vpc_id                        = each.value.vpc_id
  target_type                   = lookup(each.value, "target_type", "instance")
  deregistration_delay          = lookup(each.value, "deregistration_delay", 300)
  slow_start                    = lookup(each.value, "slow_start", 0)
  proxy_protocol_v2             = lookup(each.value, "proxy_protocol_v2", false)
  load_balancing_algorithm_type = lookup(each.value, "load_balancing_algorithm_type", null)
  preserve_client_ip            = lookup(each.value, "preserve_client_ip", null)

  dynamic "health_check" {
    for_each = lookup(each.value, "health_check", null) != null ? [each.value.health_check] : []
    content {
      enabled             = lookup(health_check.value, "enabled", true)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", 3)
      interval            = lookup(health_check.value, "interval", 30)
      matcher             = lookup(health_check.value, "matcher", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", "traffic-port")
      protocol            = lookup(health_check.value, "protocol", "HTTP")
      timeout             = lookup(health_check.value, "timeout", 5)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", 3)
    }
  }

  dynamic "stickiness" {
    for_each = lookup(each.value, "stickiness", null) != null ? [each.value.stickiness] : []
    content {
      type            = stickiness.value.type
      cookie_duration = lookup(stickiness.value, "cookie_duration", null)
      cookie_name     = lookup(stickiness.value, "cookie_name", null)
    }
  }

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
  )
}

# Listeners
resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = lookup(each.value, "ssl_policy", null)
  certificate_arn   = lookup(each.value, "certificate_arn", null)

  dynamic "default_action" {
    for_each = [each.value.default_action]
    content {
      type             = default_action.value.type
      target_group_arn = lookup(default_action.value, "target_group_arn", null)

      dynamic "fixed_response" {
        for_each = lookup(default_action.value, "fixed_response", null) != null ? [default_action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = lookup(fixed_response.value, "message_body", null)
          status_code  = lookup(fixed_response.value, "status_code", null)
        }
      }

      dynamic "redirect" {
        for_each = lookup(default_action.value, "redirect", null) != null ? [default_action.value.redirect] : []
        content {
          path        = lookup(redirect.value, "path", null)
          host        = lookup(redirect.value, "host", null)
          port        = lookup(redirect.value, "port", null)
          protocol    = lookup(redirect.value, "protocol", null)
          query       = lookup(redirect.value, "query", null)
          status_code = redirect.value.status_code
        }
      }
    }
  }
}

# Listener Rules
resource "aws_lb_listener_rule" "this" {
  for_each = var.listener_rules

  listener_arn = aws_lb_listener.this[each.value.listener_key].arn
  priority     = lookup(each.value, "priority", null)

  dynamic "action" {
    for_each = [each.value.action]
    content {
      type             = action.value.type
      target_group_arn = lookup(action.value, "target_group_arn", null)

      dynamic "fixed_response" {
        for_each = lookup(action.value, "fixed_response", null) != null ? [action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = lookup(fixed_response.value, "message_body", null)
          status_code  = lookup(fixed_response.value, "status_code", null)
        }
      }

      dynamic "redirect" {
        for_each = lookup(action.value, "redirect", null) != null ? [action.value.redirect] : []
        content {
          path        = lookup(redirect.value, "path", null)
          host        = lookup(redirect.value, "host", null)
          port        = lookup(redirect.value, "port", null)
          protocol    = lookup(redirect.value, "protocol", null)
          query       = lookup(redirect.value, "query", null)
          status_code = redirect.value.status_code
        }
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      dynamic "host_header" {
        for_each = lookup(condition.value, "host_header", null) != null ? [condition.value.host_header] : []
        content {
          values = host_header.value.values
        }
      }

      dynamic "http_header" {
        for_each = lookup(condition.value, "http_header", null) != null ? [condition.value.http_header] : []
        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }

      dynamic "path_pattern" {
        for_each = lookup(condition.value, "path_pattern", null) != null ? [condition.value.path_pattern] : []
        content {
          values = path_pattern.value.values
        }
      }

      dynamic "query_string" {
        for_each = lookup(condition.value, "query_string", null) != null ? condition.value.query_string : []
        content {
          key   = lookup(query_string.value, "key", null)
          value = query_string.value.value
        }
      }

      dynamic "source_ip" {
        for_each = lookup(condition.value, "source_ip", null) != null ? [condition.value.source_ip] : []
        content {
          values = source_ip.value.values
        }
      }
    }
  }
}
