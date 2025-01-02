locals {
  is_application = var.load_balancer_type == "application"
  is_network     = var.load_balancer_type == "network"
}

# Load Balancer
resource "aws_lb" "load_balancer" {
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
      allocation_id        = subnet_mapping.value.allocation_id
      private_ipv4_address = subnet_mapping.value.private_ipv4_address
      ipv6_address         = subnet_mapping.value.ipv6_address
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
resource "aws_lb_target_group" "target_group" {
  for_each = var.target_groups

  name                          = var.target_group_name
  name_prefix                   = var.target_group_name_prefix
  port                          = var.target_group_port
  protocol                      = var.target_group_protocol
  vpc_id                        = var.target_group_vpc_id
  target_type                   = var.target_group_target_type
  deregistration_delay          = var.target_group_deregistration_delay
  slow_start                    = var.target_group_slow_start
  proxy_protocol_v2             = var.target_group_proxy_protocol_v2
  load_balancing_algorithm_type = var.target_group_load_balancing_algorithm_type
  preserve_client_ip            = var.target_group_preserve_client_ip

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []
    content {
      enabled             = health_check.value.enabled
      healthy_threshold   = health_check.value.healthy_threshold
      interval            = health_check.value.interval
      matcher             = health_check.value.matcher
      path                = health_check.value.path
      port                = health_check.value.port
      protocol            = health_check.value.protocol
      timeout             = health_check.value.timeout
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      cookie_name     = stickiness.value.cookie_name
    }
  }

  tags = merge(
    var.tags,
    each.value.tags
  )
}

# Listeners
resource "aws_lb_listener" "listener" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.load_balancer.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = each.value.ssl_policy
  certificate_arn   = each.value.certificate_arn

  dynamic "default_action" {
    for_each = [each.value.default_action]
    content {
      type             = default_action.value.type
      target_group_arn = aws_lb_target_group.target_group["main"].arn

      dynamic "fixed_response" {
        for_each = default_action.value.fixed_response != null ? [default_action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      dynamic "redirect" {
        for_each = default_action.value.redirect != null ? [default_action.value.redirect] : []
        content {
          path        = redirect.value.path
          host        = redirect.value.host
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          query       = redirect.value.query
          status_code = redirect.value.status_code
        }
      }
    }
  }
}

# Listener Rules
resource "aws_lb_listener_rule" "listener_rule" {
  for_each = var.listener_rules

  listener_arn = aws_lb_listener.listener[each.value.listener_key].arn
  priority     = each.value.priority

  dynamic "action" {
    for_each = [each.value.action]
    content {
      type             = action.value.type
      target_group_arn = aws_lb_target_group.target_group["main"].arn

      dynamic "fixed_response" {
        for_each = action.value.fixed_response != null ? [action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      dynamic "redirect" {
        for_each = action.value.redirect != null ? [action.value.redirect] : []
        content {
          path        = redirect.value.path
          host        = redirect.value.host
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          query       = redirect.value.query
          status_code = redirect.value.status_code
        }
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      dynamic "host_header" {
        for_each = condition.value.host_header != null ? [condition.value.host_header] : []
        content {
          values = host_header.value.values
        }
      }

      dynamic "http_header" {
        for_each = condition.value.http_header != null ? [condition.value.http_header] : []
        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }

      dynamic "path_pattern" {
        for_each = condition.value.path_pattern != null ? [condition.value.path_pattern] : []
        content {
          values = path_pattern.value.values
        }
      }

      dynamic "query_string" {
        for_each = condition.value.query_string != null ? [condition.value.query_string] : []
        content {
          key   = query_string.value.key
          value = query_string.value.value
        }
      }

      dynamic "source_ip" {
        for_each = condition.value.source_ip != null ? [condition.value.source_ip] : []
        content {
          values = source_ip.value.values
        }
      }
    }
  }
}
