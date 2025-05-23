###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Locals
###########################

locals {
  is_application      = var.load_balancer_type == "application"
  is_network          = var.load_balancer_type == "network"
  use_subnet_mappings = var.subnet_mappings != null && length(var.subnet_mappings) > 0
}

###########################################################
# Load Balancer
###########################################################

resource "aws_lb" "load_balancer" {
  # Common settings
  name                       = var.name
  internal                   = var.internal
  load_balancer_type         = var.load_balancer_type
  enable_deletion_protection = var.enable_deletion_protection
  customer_owned_ipv4_pool   = var.customer_owned_ipv4_pool
  ip_address_type            = var.ip_address_type
  security_groups            = var.security_groups
  enable_zonal_shift         = var.enable_zonal_shift

  dynamic "subnet_mapping" {
    for_each = local.use_subnet_mappings ? var.subnet_mappings : {}
    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = subnet_mapping.value.allocation_id
      private_ipv4_address = subnet_mapping.value.private_ipv4_address
      ipv6_address         = subnet_mapping.value.ipv6_address
    }
  }

  # Application Load Balancer specific settings
  desync_mitigation_mode                      = local.is_application ? var.desync_mitigation_mode : null
  idle_timeout                                = local.is_application ? var.idle_timeout : null
  drop_invalid_header_fields                  = local.is_application ? var.drop_invalid_header_fields : null
  enable_http2                                = local.is_application ? var.enable_http2 : null
  enable_waf_fail_open                        = local.is_application ? var.enable_waf_fail_open : null
  client_keep_alive                           = local.is_application ? var.client_keep_alive : null
  enable_tls_version_and_cipher_suite_headers = local.is_application ? var.enable_tls_version_and_cipher_suite_headers : null
  enable_xff_client_port                      = local.is_application ? var.enable_xff_client_port : null
  xff_header_processing_mode                  = local.is_application ? var.xff_header_processing_mode : null
  preserve_host_header                        = local.is_application ? var.preserve_host_header : null

  dynamic "connection_logs" {
    for_each = local.is_application && var.connection_logs != null ? { create = var.connection_logs } : {}
    content {
      bucket  = connection_logs.value.bucket
      prefix  = connection_logs.value.prefix
      enabled = connection_logs.value.enabled
    }
  }

  # Network Load Balancer specific settings
  enable_cross_zone_load_balancing                             = local.is_network ? var.enable_cross_zone_load_balancing : null
  dns_record_client_routing_policy                             = local.is_network ? var.dns_record_client_routing_policy : null
  enforce_security_group_inbound_rules_on_private_link_traffic = local.is_network ? var.enforce_security_group_inbound_rules_on_private_link_traffic : null
  dynamic "access_logs" {
    for_each = var.access_logs != null ? { create = var.access_logs } : {}
    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = access_logs.value.enabled
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    },
  )
}

###########################################################
# Target Group
###########################################################

resource "aws_lb_target_group" "target_group" {
  for_each = var.target_groups

  # Common settings
  name                 = each.value.name
  port                 = each.value.port
  protocol             = each.value.protocol
  vpc_id               = each.value.vpc_id
  target_type          = each.value.target_type
  deregistration_delay = each.value.deregistration_delay

  # Application Load Balancer specific settings
  slow_start                    = local.is_application ? each.value.slow_start : null
  load_balancing_algorithm_type = local.is_application ? each.value.load_balancing_algorithm_type : null

  # Network Load Balancer specific settings
  proxy_protocol_v2  = local.is_network ? each.value.target_group_proxy_protocol_v2 : null
  preserve_client_ip = local.is_network ? each.value.target_group_preserve_client_ip : null

  dynamic "health_check" {
    for_each = each.value.health_check != null ? each.value.health_check : {}
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
    for_each = each.value.stickiness != null ? each.value.stickiness : []
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

###########################################################
# Listeners
###########################################################

resource "aws_lb_listener" "listener" {
  for_each = var.listeners

  # Common settings
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = each.value.port
  protocol          = each.value.protocol

  # SSL/TLS settings
  ssl_policy      = each.value.ssl_policy
  certificate_arn = each.value.certificate_arn

  # Application Load Balancer specific settings
  alpn_policy = local.is_application ? each.value.alpn_policy : null

  dynamic "mutual_authentication" {
    for_each = local.is_network && each.value.mutual_authentication != null ? each.value.mutual_authentication : {}
    content {
      mode = mutual_authentication.value.mode
    }
  }



  dynamic "default_action" {
    for_each = [each.value.default_action]
    content {
      # Common settings
      type             = default_action.value.type
      target_group_arn = aws_lb_target_group.target_group["main"].arn

      # Application Load Balancer specific fixed response action
      dynamic "fixed_response" {
        for_each = default_action.value.fixed_response != null ? default_action.value.fixed_response : {}
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      # Application Load Balancer specific redirect action
      dynamic "redirect" {
        for_each = default_action.value.redirect != null ? default_action.value.redirect : {}
        content {
          path        = redirect.value.path
          host        = redirect.value.host
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          query       = redirect.value.query
          status_code = redirect.value.status_code
        }
      }

      # Application Load Balancer authentication settings
      dynamic "authenticate_oidc" {
        for_each = each.value.authenticate_oidc != null && local.is_application ? each.value.authenticate_oidc : {}
        content {
          authorization_endpoint = authenticate_oidc.value.authorization_endpoint
          client_id              = authenticate_oidc.value.client_id
          client_secret          = authenticate_oidc.value.client_secret
          issuer                 = authenticate_oidc.value.issuer
          token_endpoint         = authenticate_oidc.value.token_endpoint
          user_info_endpoint     = authenticate_oidc.value.user_info_endpoint
        }
      }

      dynamic "authenticate_cognito" {
        for_each = each.value.authenticate_cognito != null && local.is_application ? each.value.authenticate_cognito : {}
        content {
          user_pool_arn       = authenticate_cognito.value.user_pool_arn
          user_pool_client_id = authenticate_cognito.value.user_pool_client_id
          user_pool_domain    = authenticate_cognito.value.user_pool_domain
        }
      }
    }
  }
}

###########################################################
# Listener Rules
###########################################################

# (Application Load Balancer only)
resource "aws_lb_listener_rule" "listener_rule" {
  # Common settings
  for_each     = var.listener_rules
  listener_arn = aws_lb_listener.listener[each.value.listener_key].arn
  priority     = each.value.priority

  # Application Load Balancer action settings
  dynamic "action" {
    for_each = [each.value.action]
    content {
      type             = action.value.type
      target_group_arn = aws_lb_target_group.target_group["main"].arn

      # ALB fixed response action
      dynamic "fixed_response" {
        for_each = action.value.fixed_response != null ? action.value.fixed_response : {}
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      # ALB redirect action
      dynamic "redirect" {
        for_each = action.value.redirect != null ? action.value.redirect : {}
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

  # Application Load Balancer condition settings
  dynamic "condition" {
    for_each = each.value.conditions
    content {
      # ALB host header condition
      dynamic "host_header" {
        for_each = condition.value.host_header != null ? condition.value.host_header : {}
        content {
          values = host_header.value.values
        }
      }

      # ALB http header condition
      dynamic "http_header" {
        for_each = condition.value.http_header != null ? condition.value.http_header : {}
        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }

      # ALB path pattern condition
      dynamic "path_pattern" {
        for_each = condition.value.path_pattern != null ? condition.value.path_pattern : {}
        content {
          values = path_pattern.value.values
        }
      }

      # ALB query string condition
      dynamic "query_string" {
        for_each = condition.value.query_string != null ? condition.value.query_string : {}
        content {
          key   = query_string.value.key
          value = query_string.value.value
        }
      }

      # Common source IP condition (works for both ALB and NLB)
      dynamic "source_ip" {
        for_each = condition.value.source_ip != null ? { source_ip = condition.value.source_ip } : {}
        content {
          values = source_ip.value.values
        }
      }
    }
  }
}

