############################
# Provider Configuration
############################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

############################
# Locals
############################
locals {
  visibility_metric_name = coalesce(var.visibility_config.metric_name, var.name)
}

############################
# IP Sets
############################

resource "aws_wafv2_ip_set" "this" {
  for_each = var.ip_sets

  name               = each.value.name
  description        = each.value.description
  scope              = var.scope
  ip_address_version = each.value.ip_address_version
  addresses          = each.value.addresses

  tags = merge(tomap({ Name = each.value.name }), var.tags)
}

############################
# WAF ACL
############################

resource "aws_wafv2_web_acl" "this" {
  name          = var.name
  scope         = var.scope # REGIONAL or CLOUDFRONT
  description   = var.description
  token_domains = var.token_domains

  dynamic "default_action" {
    for_each = [var.default_action]
    content {
      dynamic "allow" {
        for_each = default_action.value == "allow" ? [1] : []
        content {}
      }
      dynamic "block" {
        for_each = default_action.value == "block" ? [1] : []
        content {}
      }
    }
  }

  dynamic "custom_response_body" {
    for_each = var.custom_response_body
    content {
      key          = custom_response_body.key
      content      = custom_response_body.value.content
      content_type = custom_response_body.value.content_type
    }
  }

  dynamic "association_config" {
    for_each = var.association_config != null ? [var.association_config] : []
    content {
      dynamic "request_body" {
        for_each = association_config.value.request_body != null ? [association_config.value.request_body] : []
        content {
          dynamic "api_gateway" {
            for_each = request_body.value.api_gateway != null ? [request_body.value.api_gateway] : []
            content {
              default_size_inspection_limit = api_gateway.value.default_size_inspection_limit
            }
          }
          dynamic "app_runner_service" {
            for_each = request_body.value.app_runner_service != null ? [request_body.value.app_runner_service] : []
            content {
              default_size_inspection_limit = app_runner_service.value.default_size_inspection_limit
            }
          }
          dynamic "cognito_user_pool" {
            for_each = request_body.value.cognito_user_pool != null ? [request_body.value.cognito_user_pool] : []
            content {
              default_size_inspection_limit = cognito_user_pool.value.default_size_inspection_limit
            }
          }
          dynamic "verified_access_instance" {
            for_each = request_body.value.verified_access_instance != null ? [request_body.value.verified_access_instance] : []
            content {
              default_size_inspection_limit = verified_access_instance.value.default_size_inspection_limit
            }
          }
        }
      }
    }
  }

  dynamic "captcha_config" {
    for_each = var.captcha_config != null ? [var.captcha_config] : []
    content {
      immunity_time_property {
        immunity_time = captcha_config.value.immunity_time_property.immunity_time
      }
    }
  }

  dynamic "challenge_config" {
    for_each = var.challenge_config != null ? [var.challenge_config] : []
    content {
      immunity_time_property {
        immunity_time = challenge_config.value.immunity_time_property.immunity_time
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.visibility_config.cloudwatch_metrics_enabled
    metric_name                = local.visibility_metric_name
    sampled_requests_enabled   = var.visibility_config.sampled_requests_enabled
  }

  tags = merge(tomap({ Name = var.name }), var.tags)

  lifecycle {
    ignore_changes = [rule]
  }
}

############################
# WAF Association
############################

resource "aws_wafv2_web_acl_association" "this" {
  count = var.associate_with_resource != null ? 1 : 0

  resource_arn = var.associate_with_resource
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

############################
# WAF Rules
############################

resource "aws_wafv2_web_acl_rule" "this" {
  for_each = { for k, v in var.rule : v.name => v }

  name        = each.value.name
  priority    = each.value.priority
  web_acl_arn = aws_wafv2_web_acl.this.arn

  dynamic "action" {
    for_each = each.value.action != null ? [each.value.action] : []
    content {
      dynamic "allow" {
        for_each = action.value == "allow" ? [1] : []
        content {}
      }
      dynamic "block" {
        for_each = action.value == "block" ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = action.value == "count" ? [1] : []
        content {}
      }
    }
  }

  dynamic "override_action" {
    for_each = each.value.override_action != null ? [each.value.override_action] : []
    content {
      dynamic "none" {
        for_each = override_action.value == "none" ? [1] : []
        content {}
      }
      dynamic "count" {
        for_each = override_action.value == "count" ? [1] : []
        content {}
      }
    }
  }

  statement {
    dynamic "managed_rule_group_statement" {
      for_each = each.value.statement.managed_rule_group_statement != null ? [each.value.statement.managed_rule_group_statement] : []
      content {
        name        = managed_rule_group_statement.value.name
        vendor_name = managed_rule_group_statement.value.vendor_name

        dynamic "rule_action_override" {
          for_each = coalesce(managed_rule_group_statement.value.rule_action_overrides, [])
          content {
            name = rule_action_override.value
            action_to_use {
              count {}
            }
          }
        }
      }
    }

    dynamic "not_statement" {
      for_each = each.value.statement.not_statement != null ? [each.value.statement.not_statement] : []
      content {
        statement {
          ip_set_reference_statement {
            arn = not_statement.value.ip_set_reference_statement.arn
          }
        }
      }
    }

    dynamic "ip_set_reference_statement" {
      for_each = each.value.statement.ip_set_reference_statement != null ? [each.value.statement.ip_set_reference_statement] : []
      content {
        arn = ip_set_reference_statement.value.arn
      }
    }
  }

  dynamic "captcha_config" {
    for_each = each.value.captcha_config != null ? [each.value.captcha_config] : []
    content {
      immunity_time_property {
        immunity_time = captcha_config.value.immunity_time_property.immunity_time
      }
    }
  }

  dynamic "challenge_config" {
    for_each = each.value.challenge_config != null ? [each.value.challenge_config] : []
    content {
      immunity_time_property {
        immunity_time = challenge_config.value.immunity_time_property.immunity_time
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = each.value.visibility_config.cloudwatch_metrics_enabled
    metric_name                = each.value.visibility_config.metric_name
    sampled_requests_enabled   = each.value.visibility_config.sampled_requests_enabled
  }
}

############################
# WAF Logging
############################

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count = var.logging_configuration != null ? 1 : 0

  log_destination_configs = var.logging_configuration.log_destination_configs
  resource_arn            = aws_wafv2_web_acl.this.arn

  dynamic "redacted_fields" {
    for_each = var.logging_configuration.redacted_fields
    content {
      dynamic "single_header" {
        for_each = redacted_fields.value.single_header != null ? [redacted_fields.value.single_header] : []
        content {
          name = single_header.value.name
        }
      }
      dynamic "uri_path" {
        for_each = redacted_fields.value.uri_path != null ? [1] : []
        content {}
      }
      dynamic "query_string" {
        for_each = redacted_fields.value.query_string != null ? [1] : []
        content {}
      }
      dynamic "method" {
        for_each = redacted_fields.value.method != null ? [1] : []
        content {}
      }
    }
  }

  dynamic "logging_filter" {
    for_each = var.logging_configuration.logging_filter != null ? [var.logging_configuration.logging_filter] : []
    content {
      default_behavior = logging_filter.value.default_behavior
      dynamic "filter" {
        for_each = logging_filter.value.filter
        content {
          behavior    = filter.value.behavior
          requirement = filter.value.requirement
          dynamic "condition" {
            for_each = filter.value.condition
            content {
              dynamic "action_condition" {
                for_each = condition.value.action_condition != null ? [condition.value.action_condition] : []
                content {
                  action = action_condition.value.action
                }
              }
              dynamic "label_name_condition" {
                for_each = condition.value.label_name_condition != null ? [condition.value.label_name_condition] : []
                content {
                  label_name = label_name_condition.value.label_name
                }
              }
            }
          }
        }
      }
    }
  }
}
