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

    ############################
    # Managed Rule Group
    ############################
    dynamic "managed_rule_group_statement" {
      for_each = each.value.statement.managed_rule_group_statement != null ? [each.value.statement.managed_rule_group_statement] : []
      content {
        name        = managed_rule_group_statement.value.name
        vendor_name = managed_rule_group_statement.value.vendor_name

        dynamic "rule_action_override" {
          for_each = coalesce(managed_rule_group_statement.value.rule_action_overrides, [])
          content {
            name = rule_action_override.key
            action_to_use {
              dynamic "allow" {
                for_each = rule_action_override.value.action == "allow" ? [1] : []
                content {}
              }
              dynamic "block" {
                for_each = rule_action_override.value.action == "block" ? [1] : []
                content {}
              }
              dynamic "count" {
                for_each = rule_action_override.value.action == "count" ? [1] : []
                content {}
              }
              dynamic "captcha" {
                for_each = rule_action_override.value.action == "captcha" ? [1] : []
                content {}
              }
              dynamic "challenge" {
                for_each = rule_action_override.value.action == "challenge" ? [1] : []
                content {}
              }
            }
          }
        }

        dynamic "scope_down_statement" {
          for_each = try(managed_rule_group_statement.value.scope_down_statement, null) != null ? [managed_rule_group_statement.value.scope_down_statement] : []
          content {
            dynamic "geo_match_statement" {
              for_each = try(scope_down_statement.value.geo_match_statement, null) != null ? [scope_down_statement.value.geo_match_statement] : []
              content {
                country_codes = geo_match_statement.value.country_codes
              }
            }
            dynamic "ip_set_reference_statement" {
              for_each = try(scope_down_statement.value.ip_set_reference_statement, null) != null ? [scope_down_statement.value.ip_set_reference_statement] : []
              content {
                arn = ip_set_reference_statement.value.arn
              }
            }
            dynamic "label_match_statement" {
              for_each = try(scope_down_statement.value.label_match_statement, null) != null ? [scope_down_statement.value.label_match_statement] : []
              content {
                key   = label_match_statement.value.key
                scope = label_match_statement.value.scope
              }
            }
            dynamic "byte_match_statement" {
              for_each = try(scope_down_statement.value.byte_match_statement, null) != null ? [scope_down_statement.value.byte_match_statement] : []
              content {
                positional_constraint = byte_match_statement.value.positional_constraint
                search_string         = byte_match_statement.value.search_string
                dynamic "field_to_match" {
                  for_each = [byte_match_statement.value.field_to_match]
                  content {
                    dynamic "all_query_arguments" {
                      for_each = try(field_to_match.value.all_query_arguments, false) ? [1] : []
                      content {}
                    }
                    dynamic "body" {
                      for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                      content {
                        oversize_handling = body.value.oversize_handling
                      }
                    }
                    dynamic "method" {
                      for_each = try(field_to_match.value.method, false) ? [1] : []
                      content {}
                    }
                    dynamic "query_string" {
                      for_each = try(field_to_match.value.query_string, false) ? [1] : []
                      content {}
                    }
                    dynamic "uri_path" {
                      for_each = try(field_to_match.value.uri_path, false) ? [1] : []
                      content {}
                    }
                    dynamic "single_header" {
                      for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                      content {
                        name = single_header.value.name
                      }
                    }
                    dynamic "single_query_argument" {
                      for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
                      content {
                        name = single_query_argument.value.name
                      }
                    }
                  }
                }
                dynamic "text_transformation" {
                  for_each = byte_match_statement.value.text_transformation
                  content {
                    priority = text_transformation.value.priority
                    type     = text_transformation.value.type
                  }
                }
              }
            }
          }
        }
      }
    }

    ############################
    # IP Set Reference
    ############################
    dynamic "ip_set_reference_statement" {
      for_each = each.value.statement.ip_set_reference_statement != null ? [each.value.statement.ip_set_reference_statement] : []
      content {
        arn = ip_set_reference_statement.value.arn
      }
    }

    ############################
    # Geo Match
    ############################
    dynamic "geo_match_statement" {
      for_each = each.value.statement.geo_match_statement != null ? [each.value.statement.geo_match_statement] : []
      content {
        country_codes = geo_match_statement.value.country_codes
        dynamic "forwarded_ip_config" {
          for_each = try(geo_match_statement.value.forwarded_ip_config, null) != null ? [geo_match_statement.value.forwarded_ip_config] : []
          content {
            header_name       = forwarded_ip_config.value.header_name
            fallback_behavior = forwarded_ip_config.value.fallback_behavior
          }
        }
      }
    }

    ############################
    # Rate Based
    ############################
    dynamic "rate_based_statement" {
      for_each = each.value.statement.rate_based_statement != null ? [each.value.statement.rate_based_statement] : []
      content {
        limit                 = rate_based_statement.value.limit
        aggregate_key_type    = rate_based_statement.value.aggregate_key_type
        evaluation_window_sec = try(rate_based_statement.value.evaluation_window_sec, null)
        dynamic "forwarded_ip_config" {
          for_each = try(rate_based_statement.value.forwarded_ip_config, null) != null ? [rate_based_statement.value.forwarded_ip_config] : []
          content {
            header_name       = forwarded_ip_config.value.header_name
            fallback_behavior = forwarded_ip_config.value.fallback_behavior
          }
        }
        dynamic "scope_down_statement" {
          for_each = try(rate_based_statement.value.scope_down_statement, null) != null ? [rate_based_statement.value.scope_down_statement] : []
          content {
            dynamic "geo_match_statement" {
              for_each = try(scope_down_statement.value.geo_match_statement, null) != null ? [scope_down_statement.value.geo_match_statement] : []
              content {
                country_codes = geo_match_statement.value.country_codes
              }
            }
            dynamic "ip_set_reference_statement" {
              for_each = try(scope_down_statement.value.ip_set_reference_statement, null) != null ? [scope_down_statement.value.ip_set_reference_statement] : []
              content {
                arn = ip_set_reference_statement.value.arn
              }
            }
            dynamic "label_match_statement" {
              for_each = try(scope_down_statement.value.label_match_statement, null) != null ? [scope_down_statement.value.label_match_statement] : []
              content {
                key   = label_match_statement.value.key
                scope = label_match_statement.value.scope
              }
            }
          }
        }
      }
    }

    ############################
    # Byte Match
    ############################
    dynamic "byte_match_statement" {
      for_each = each.value.statement.byte_match_statement != null ? [each.value.statement.byte_match_statement] : []
      content {
        positional_constraint = byte_match_statement.value.positional_constraint
        search_string         = byte_match_statement.value.search_string
        dynamic "field_to_match" {
          for_each = [byte_match_statement.value.field_to_match]
          content {
            dynamic "all_query_arguments" {
              for_each = try(field_to_match.value.all_query_arguments, false) ? [1] : []
              content {}
            }
            dynamic "body" {
              for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
              content {
                oversize_handling = body.value.oversize_handling
              }
            }
            dynamic "method" {
              for_each = try(field_to_match.value.method, false) ? [1] : []
              content {}
            }
            dynamic "query_string" {
              for_each = try(field_to_match.value.query_string, false) ? [1] : []
              content {}
            }
            dynamic "uri_path" {
              for_each = try(field_to_match.value.uri_path, false) ? [1] : []
              content {}
            }
            dynamic "single_header" {
              for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
              content {
                name = single_header.value.name
              }
            }
            dynamic "single_query_argument" {
              for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
              content {
                name = single_query_argument.value.name
              }
            }
            dynamic "headers" {
              for_each = try(field_to_match.value.headers, null) != null ? [field_to_match.value.headers] : []
              content {
                match_scope       = headers.value.match_scope
                oversize_handling = headers.value.oversize_handling
                match_pattern {
                  dynamic "all" {
                    for_each = try(headers.value.match_pattern.all, false) ? [1] : []
                    content {}
                  }
                  included_headers = try(headers.value.match_pattern.included_headers, [])
                  excluded_headers = try(headers.value.match_pattern.excluded_headers, [])
                }
              }
            }
            dynamic "cookies" {
              for_each = try(field_to_match.value.cookies, null) != null ? [field_to_match.value.cookies] : []
              content {
                match_scope       = cookies.value.match_scope
                oversize_handling = cookies.value.oversize_handling
                match_pattern {
                  dynamic "all" {
                    for_each = try(cookies.value.match_pattern.all, false) ? [1] : []
                    content {}
                  }
                  included_cookies = try(cookies.value.match_pattern.included_cookies, [])
                  excluded_cookies = try(cookies.value.match_pattern.excluded_cookies, [])
                }
              }
            }
          }
        }
        dynamic "text_transformation" {
          for_each = byte_match_statement.value.text_transformation
          content {
            priority = text_transformation.value.priority
            type     = text_transformation.value.type
          }
        }
      }
    }

    ############################
    # Size Constraint
    ############################
    dynamic "size_constraint_statement" {
      for_each = each.value.statement.size_constraint_statement != null ? [each.value.statement.size_constraint_statement] : []
      content {
        comparison_operator = size_constraint_statement.value.comparison_operator
        size                = size_constraint_statement.value.size
        dynamic "field_to_match" {
          for_each = [size_constraint_statement.value.field_to_match]
          content {
            dynamic "all_query_arguments" {
              for_each = try(field_to_match.value.all_query_arguments, false) ? [1] : []
              content {}
            }
            dynamic "body" {
              for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
              content {
                oversize_handling = body.value.oversize_handling
              }
            }
            dynamic "method" {
              for_each = try(field_to_match.value.method, false) ? [1] : []
              content {}
            }
            dynamic "query_string" {
              for_each = try(field_to_match.value.query_string, false) ? [1] : []
              content {}
            }
            dynamic "uri_path" {
              for_each = try(field_to_match.value.uri_path, false) ? [1] : []
              content {}
            }
            dynamic "single_header" {
              for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
              content {
                name = single_header.value.name
              }
            }
            dynamic "single_query_argument" {
              for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
              content {
                name = single_query_argument.value.name
              }
            }
          }
        }
        dynamic "text_transformation" {
          for_each = size_constraint_statement.value.text_transformation
          content {
            priority = text_transformation.value.priority
            type     = text_transformation.value.type
          }
        }
      }
    }

    ############################
    # SQLi Match
    ############################
    dynamic "sqli_match_statement" {
      for_each = each.value.statement.sqli_match_statement != null ? [each.value.statement.sqli_match_statement] : []
      content {
        sensitivity_level = sqli_match_statement.value.sensitivity_level
        dynamic "field_to_match" {
          for_each = [sqli_match_statement.value.field_to_match]
          content {
            dynamic "all_query_arguments" {
              for_each = try(field_to_match.value.all_query_arguments, false) ? [1] : []
              content {}
            }
            dynamic "body" {
              for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
              content {
                oversize_handling = body.value.oversize_handling
              }
            }
            dynamic "method" {
              for_each = try(field_to_match.value.method, false) ? [1] : []
              content {}
            }
            dynamic "query_string" {
              for_each = try(field_to_match.value.query_string, false) ? [1] : []
              content {}
            }
            dynamic "uri_path" {
              for_each = try(field_to_match.value.uri_path, false) ? [1] : []
              content {}
            }
            dynamic "single_header" {
              for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
              content {
                name = single_header.value.name
              }
            }
            dynamic "single_query_argument" {
              for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
              content {
                name = single_query_argument.value.name
              }
            }
          }
        }
        dynamic "text_transformation" {
          for_each = sqli_match_statement.value.text_transformation
          content {
            priority = text_transformation.value.priority
            type     = text_transformation.value.type
          }
        }
      }
    }

    ############################
    # XSS Match
    ############################
    dynamic "xss_match_statement" {
      for_each = each.value.statement.xss_match_statement != null ? [each.value.statement.xss_match_statement] : []
      content {
        dynamic "field_to_match" {
          for_each = [xss_match_statement.value.field_to_match]
          content {
            dynamic "all_query_arguments" {
              for_each = try(field_to_match.value.all_query_arguments, false) ? [1] : []
              content {}
            }
            dynamic "body" {
              for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
              content {
                oversize_handling = body.value.oversize_handling
              }
            }
            dynamic "method" {
              for_each = try(field_to_match.value.method, false) ? [1] : []
              content {}
            }
            dynamic "query_string" {
              for_each = try(field_to_match.value.query_string, false) ? [1] : []
              content {}
            }
            dynamic "uri_path" {
              for_each = try(field_to_match.value.uri_path, false) ? [1] : []
              content {}
            }
            dynamic "single_header" {
              for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
              content {
                name = single_header.value.name
              }
            }
            dynamic "single_query_argument" {
              for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
              content {
                name = single_query_argument.value.name
              }
            }
          }
        }
        dynamic "text_transformation" {
          for_each = xss_match_statement.value.text_transformation
          content {
            priority = text_transformation.value.priority
            type     = text_transformation.value.type
          }
        }
      }
    }

    ############################
    # Regex Match
    ############################
    dynamic "regex_match_statement" {
      for_each = each.value.statement.regex_match_statement != null ? [each.value.statement.regex_match_statement] : []
      content {
        regex_string = regex_match_statement.value.regex_string
        dynamic "field_to_match" {
          for_each = [regex_match_statement.value.field_to_match]
          content {
            dynamic "all_query_arguments" {
              for_each = try(field_to_match.value.all_query_arguments, false) ? [1] : []
              content {}
            }
            dynamic "body" {
              for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
              content {
                oversize_handling = body.value.oversize_handling
              }
            }
            dynamic "method" {
              for_each = try(field_to_match.value.method, false) ? [1] : []
              content {}
            }
            dynamic "query_string" {
              for_each = try(field_to_match.value.query_string, false) ? [1] : []
              content {}
            }
            dynamic "uri_path" {
              for_each = try(field_to_match.value.uri_path, false) ? [1] : []
              content {}
            }
            dynamic "single_header" {
              for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
              content {
                name = single_header.value.name
              }
            }
            dynamic "single_query_argument" {
              for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
              content {
                name = single_query_argument.value.name
              }
            }
          }
        }
        dynamic "text_transformation" {
          for_each = regex_match_statement.value.text_transformation
          content {
            priority = text_transformation.value.priority
            type     = text_transformation.value.type
          }
        }
      }
    }

    ############################
    # Regex Pattern Set Reference
    ############################
    dynamic "regex_pattern_set_reference_statement" {
      for_each = each.value.statement.regex_pattern_set_reference_statement != null ? [each.value.statement.regex_pattern_set_reference_statement] : []
      content {
        arn = regex_pattern_set_reference_statement.value.arn
        dynamic "field_to_match" {
          for_each = [regex_pattern_set_reference_statement.value.field_to_match]
          content {
            dynamic "all_query_arguments" {
              for_each = try(field_to_match.value.all_query_arguments, false) ? [1] : []
              content {}
            }
            dynamic "body" {
              for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
              content {
                oversize_handling = body.value.oversize_handling
              }
            }
            dynamic "method" {
              for_each = try(field_to_match.value.method, false) ? [1] : []
              content {}
            }
            dynamic "query_string" {
              for_each = try(field_to_match.value.query_string, false) ? [1] : []
              content {}
            }
            dynamic "uri_path" {
              for_each = try(field_to_match.value.uri_path, false) ? [1] : []
              content {}
            }
            dynamic "single_header" {
              for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
              content {
                name = single_header.value.name
              }
            }
            dynamic "single_query_argument" {
              for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
              content {
                name = single_query_argument.value.name
              }
            }
          }
        }
        dynamic "text_transformation" {
          for_each = regex_pattern_set_reference_statement.value.text_transformation
          content {
            priority = text_transformation.value.priority
            type     = text_transformation.value.type
          }
        }
      }
    }

    ############################
    # Label Match
    ############################
    dynamic "label_match_statement" {
      for_each = each.value.statement.label_match_statement != null ? [each.value.statement.label_match_statement] : []
      content {
        key   = label_match_statement.value.key
        scope = label_match_statement.value.scope
      }
    }

    ############################
    # Rule Group Reference
    ############################
    dynamic "rule_group_reference_statement" {
      for_each = each.value.statement.rule_group_reference_statement != null ? [each.value.statement.rule_group_reference_statement] : []
      content {
        arn = rule_group_reference_statement.value.arn
        dynamic "rule_action_override" {
          for_each = rule_group_reference_statement.value.rule_action_overrides
          content {
            name = rule_action_override.key
            action_to_use {
              dynamic "allow" {
                for_each = rule_action_override.value.action == "allow" ? [1] : []
                content {}
              }
              dynamic "block" {
                for_each = rule_action_override.value.action == "block" ? [1] : []
                content {}
              }
              dynamic "count" {
                for_each = rule_action_override.value.action == "count" ? [1] : []
                content {}
              }
              dynamic "captcha" {
                for_each = rule_action_override.value.action == "captcha" ? [1] : []
                content {}
              }
              dynamic "challenge" {
                for_each = rule_action_override.value.action == "challenge" ? [1] : []
                content {}
              }
            }
          }
        }
      }
    }

    ############################
    # NOT Statement (1 level deep)
    ############################
    dynamic "not_statement" {
      for_each = each.value.statement.not_statement != null ? [each.value.statement.not_statement] : []
      content {
        statement {
          dynamic "geo_match_statement" {
            for_each = try(not_statement.value.statement.geo_match_statement, null) != null ? [not_statement.value.statement.geo_match_statement] : []
            content {
              country_codes = geo_match_statement.value.country_codes
            }
          }
          dynamic "ip_set_reference_statement" {
            for_each = try(not_statement.value.statement.ip_set_reference_statement, null) != null ? [not_statement.value.statement.ip_set_reference_statement] : []
            content {
              arn = ip_set_reference_statement.value.arn
            }
          }
          dynamic "label_match_statement" {
            for_each = try(not_statement.value.statement.label_match_statement, null) != null ? [not_statement.value.statement.label_match_statement] : []
            content {
              key   = label_match_statement.value.key
              scope = label_match_statement.value.scope
            }
          }
          dynamic "rate_based_statement" {
            for_each = try(not_statement.value.statement.rate_based_statement, null) != null ? [not_statement.value.statement.rate_based_statement] : []
            content {
              limit              = rate_based_statement.value.limit
              aggregate_key_type = rate_based_statement.value.aggregate_key_type
            }
          }
          dynamic "byte_match_statement" {
            for_each = try(not_statement.value.statement.byte_match_statement, null) != null ? [not_statement.value.statement.byte_match_statement] : []
            content {
              positional_constraint = byte_match_statement.value.positional_constraint
              search_string         = byte_match_statement.value.search_string
              dynamic "field_to_match" {
                for_each = [byte_match_statement.value.field_to_match]
                content {
                  dynamic "all_query_arguments" {
                    for_each = try(field_to_match.value.all_query_arguments, false) ? [1] : []
                    content {}
                  }
                  dynamic "uri_path" {
                    for_each = try(field_to_match.value.uri_path, false) ? [1] : []
                    content {}
                  }
                  dynamic "single_header" {
                    for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                    content {
                      name = single_header.value.name
                    }
                  }
                  dynamic "single_query_argument" {
                    for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
                    content {
                      name = single_query_argument.value.name
                    }
                  }
                  dynamic "query_string" {
                    for_each = try(field_to_match.value.query_string, false) ? [1] : []
                    content {}
                  }
                  dynamic "method" {
                    for_each = try(field_to_match.value.method, false) ? [1] : []
                    content {}
                  }
                  dynamic "body" {
                    for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                    content {
                      oversize_handling = body.value.oversize_handling
                    }
                  }
                }
              }
              dynamic "text_transformation" {
                for_each = byte_match_statement.value.text_transformation
                content {
                  priority = text_transformation.value.priority
                  type     = text_transformation.value.type
                }
              }
            }
          }
        }
      }
    }

    ############################
    # AND Statement (1 level deep)
    ############################
    dynamic "and_statement" {
      for_each = each.value.statement.and_statement != null ? [each.value.statement.and_statement] : []
      content {
        dynamic "statement" {
          for_each = and_statement.value.statements
          content {
            dynamic "geo_match_statement" {
              for_each = try(statement.value.geo_match_statement, null) != null ? [statement.value.geo_match_statement] : []
              content {
                country_codes = geo_match_statement.value.country_codes
              }
            }
            dynamic "ip_set_reference_statement" {
              for_each = try(statement.value.ip_set_reference_statement, null) != null ? [statement.value.ip_set_reference_statement] : []
              content {
                arn = ip_set_reference_statement.value.arn
              }
            }
            dynamic "label_match_statement" {
              for_each = try(statement.value.label_match_statement, null) != null ? [statement.value.label_match_statement] : []
              content {
                key   = label_match_statement.value.key
                scope = label_match_statement.value.scope
              }
            }
            dynamic "rate_based_statement" {
              for_each = try(statement.value.rate_based_statement, null) != null ? [statement.value.rate_based_statement] : []
              content {
                limit              = rate_based_statement.value.limit
                aggregate_key_type = rate_based_statement.value.aggregate_key_type
              }
            }
            dynamic "byte_match_statement" {
              for_each = try(statement.value.byte_match_statement, null) != null ? [statement.value.byte_match_statement] : []
              content {
                positional_constraint = byte_match_statement.value.positional_constraint
                search_string         = byte_match_statement.value.search_string
                dynamic "field_to_match" {
                  for_each = [byte_match_statement.value.field_to_match]
                  content {
                    dynamic "all_query_arguments" {
                      for_each = try(field_to_match.value.all_query_arguments, false) ? [1] : []
                      content {}
                    }
                    dynamic "uri_path" {
                      for_each = try(field_to_match.value.uri_path, false) ? [1] : []
                      content {}
                    }
                    dynamic "single_header" {
                      for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                      content {
                        name = single_header.value.name
                      }
                    }
                    dynamic "single_query_argument" {
                      for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
                      content {
                        name = single_query_argument.value.name
                      }
                    }
                    dynamic "query_string" {
                      for_each = try(field_to_match.value.query_string, false) ? [1] : []
                      content {}
                    }
                    dynamic "method" {
                      for_each = try(field_to_match.value.method, false) ? [1] : []
                      content {}
                    }
                    dynamic "body" {
                      for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                      content {
                        oversize_handling = body.value.oversize_handling
                      }
                    }
                  }
                }
                dynamic "text_transformation" {
                  for_each = byte_match_statement.value.text_transformation
                  content {
                    priority = text_transformation.value.priority
                    type     = text_transformation.value.type
                  }
                }
              }
            }
          }
        }
      }
    }

    ############################
    # OR Statement (1 level deep)
    ############################
    dynamic "or_statement" {
      for_each = each.value.statement.or_statement != null ? [each.value.statement.or_statement] : []
      content {
        dynamic "statement" {
          for_each = or_statement.value.statements
          content {
            dynamic "geo_match_statement" {
              for_each = try(statement.value.geo_match_statement, null) != null ? [statement.value.geo_match_statement] : []
              content {
                country_codes = geo_match_statement.value.country_codes
              }
            }
            dynamic "ip_set_reference_statement" {
              for_each = try(statement.value.ip_set_reference_statement, null) != null ? [statement.value.ip_set_reference_statement] : []
              content {
                arn = ip_set_reference_statement.value.arn
              }
            }
            dynamic "label_match_statement" {
              for_each = try(statement.value.label_match_statement, null) != null ? [statement.value.label_match_statement] : []
              content {
                key   = label_match_statement.value.key
                scope = label_match_statement.value.scope
              }
            }
            dynamic "byte_match_statement" {
              for_each = try(statement.value.byte_match_statement, null) != null ? [statement.value.byte_match_statement] : []
              content {
                positional_constraint = byte_match_statement.value.positional_constraint
                search_string         = byte_match_statement.value.search_string
                dynamic "field_to_match" {
                  for_each = [byte_match_statement.value.field_to_match]
                  content {
                    dynamic "all_query_arguments" {
                      for_each = try(field_to_match.value.all_query_arguments, false) ? [1] : []
                      content {}
                    }
                    dynamic "uri_path" {
                      for_each = try(field_to_match.value.uri_path, false) ? [1] : []
                      content {}
                    }
                    dynamic "single_header" {
                      for_each = try(field_to_match.value.single_header, null) != null ? [field_to_match.value.single_header] : []
                      content {
                        name = single_header.value.name
                      }
                    }
                    dynamic "single_query_argument" {
                      for_each = try(field_to_match.value.single_query_argument, null) != null ? [field_to_match.value.single_query_argument] : []
                      content {
                        name = single_query_argument.value.name
                      }
                    }
                    dynamic "query_string" {
                      for_each = try(field_to_match.value.query_string, false) ? [1] : []
                      content {}
                    }
                    dynamic "method" {
                      for_each = try(field_to_match.value.method, false) ? [1] : []
                      content {}
                    }
                    dynamic "body" {
                      for_each = try(field_to_match.value.body, null) != null ? [field_to_match.value.body] : []
                      content {
                        oversize_handling = body.value.oversize_handling
                      }
                    }
                  }
                }
                dynamic "text_transformation" {
                  for_each = byte_match_statement.value.text_transformation
                  content {
                    priority = text_transformation.value.priority
                    type     = text_transformation.value.type
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  captcha_config {
    immunity_time_property {
      immunity_time = try(each.value.captcha_config.immunity_time_property.immunity_time, 300)
    }
  }

  challenge_config {
    immunity_time_property {
      immunity_time = try(each.value.challenge_config.immunity_time_property.immunity_time, 300)
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
