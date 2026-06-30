###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Locals
###########################

###########################
# Module Configuration
###########################
resource "datadog_synthetics_test" "this" {
  for_each = var.tests

  name       = each.value.name
  type       = each.value.type
  subtype    = each.value.subtype
  status     = each.value.status
  message    = each.value.message
  locations  = each.value.locations
  tags       = each.value.tags
  set_cookie = each.value.set_cookie
  device_ids = each.value.device_ids

  ###########################
  # Request Definition
  ###########################
  dynamic "request_definition" {
    for_each = each.value.request_definition != null ? [each.value.request_definition] : []
    content {
      method                  = request_definition.value.method
      url                     = request_definition.value.url
      host                    = request_definition.value.host
      port                    = request_definition.value.port
      body                    = request_definition.value.body
      body_type               = request_definition.value.body_type
      timeout                 = request_definition.value.timeout
      no_saving_response_body = request_definition.value.no_saving_response_body
      number_of_packets       = request_definition.value.number_of_packets
      should_track_hops       = request_definition.value.should_track_hops
      persist_cookies         = request_definition.value.persist_cookies
      dns_server              = request_definition.value.dns_server
      dns_server_port         = request_definition.value.dns_server_port
      message                 = request_definition.value.message
      servername              = request_definition.value.servername
      call_type               = request_definition.value.call_type
      service                 = request_definition.value.service
      plain_proto_file        = request_definition.value.plain_proto_file
      mcp_protocol_version    = request_definition.value.mcp_protocol_version
    }
  }

  request_headers  = each.value.request_headers
  request_query    = each.value.request_query
  request_metadata = each.value.request_metadata

  ###########################
  # Request Auth
  ###########################
  dynamic "request_basicauth" {
    for_each = each.value.request_basicauth != null ? [each.value.request_basicauth] : []
    content {
      type                     = request_basicauth.value.type
      username                 = request_basicauth.value.username
      password                 = request_basicauth.value.password
      access_token_url         = request_basicauth.value.access_token_url
      token_api_authentication = request_basicauth.value.token_api_authentication
      client_id                = request_basicauth.value.client_id
      client_secret            = request_basicauth.value.client_secret
      resource                 = request_basicauth.value.resource
      scope                    = request_basicauth.value.scope
      audience                 = request_basicauth.value.audience
      workstation              = request_basicauth.value.workstation
      domain                   = request_basicauth.value.domain
    }
  }

  dynamic "request_client_certificate" {
    for_each = each.value.request_client_certificate != null ? [each.value.request_client_certificate] : []
    content {
      dynamic "cert" {
        for_each = request_client_certificate.value.cert != null ? [request_client_certificate.value.cert] : []
        content {
          content  = cert.value.content
          filename = cert.value.filename
        }
      }
      dynamic "key" {
        for_each = request_client_certificate.value.key != null ? [request_client_certificate.value.key] : []
        content {
          content  = key.value.content
          filename = key.value.filename
        }
      }
    }
  }

  dynamic "request_proxy" {
    for_each = each.value.request_proxy != null ? [each.value.request_proxy] : []
    content {
      url     = request_proxy.value.url
      headers = request_proxy.value.headers
    }
  }

  ###########################
  # Assertions
  ###########################
  dynamic "assertion" {
    for_each = each.value.assertions
    content {
      type     = assertion.value.type
      operator = assertion.value.operator
      target   = assertion.value.target
      property = assertion.value.property

      dynamic "target_mcp_capabilities" {
        for_each = assertion.value.target_mcp_capabilities != null ? [assertion.value.target_mcp_capabilities] : []
        content {
          capabilities = target_mcp_capabilities.value.capabilities
        }
      }
    }
  }

  ###########################
  # Options
  ###########################
  dynamic "options_list" {
    for_each = each.value.options_list != null ? [each.value.options_list] : []
    content {
      tick_every                        = options_list.value.tick_every
      accept_self_signed                = options_list.value.accept_self_signed
      allow_insecure                    = options_list.value.allow_insecure
      blocked_request_patterns          = options_list.value.blocked_request_patterns
      check_certificate_revocation      = options_list.value.check_certificate_revocation
      disable_aia_intermediate_fetching = options_list.value.disable_aia_intermediate_fetching
      disable_cors                      = options_list.value.disable_cors
      disable_csp                       = options_list.value.disable_csp
      follow_redirects                  = options_list.value.follow_redirects
      http_version                      = options_list.value.http_version
      ignore_server_certificate_error   = options_list.value.ignore_server_certificate_error
      initial_navigation_timeout        = options_list.value.initial_navigation_timeout
      min_failure_duration              = options_list.value.min_failure_duration
      min_location_failed               = options_list.value.min_location_failed
      monitor_name                      = options_list.value.monitor_name
      monitor_priority                  = options_list.value.monitor_priority
      no_screenshot                     = options_list.value.no_screenshot
      restricted_roles                  = options_list.value.restricted_roles

      dynamic "retry" {
        for_each = options_list.value.retry != null ? [options_list.value.retry] : []
        content {
          count    = retry.value.count
          interval = retry.value.interval
        }
      }

      dynamic "monitor_options" {
        for_each = options_list.value.monitor_options != null ? [options_list.value.monitor_options] : []
        content {
          escalation_message       = monitor_options.value.escalation_message
          notification_preset_name = monitor_options.value.notification_preset_name
          renotify_interval        = monitor_options.value.renotify_interval
          renotify_occurrences     = monitor_options.value.renotify_occurrences
        }
      }

      dynamic "scheduling" {
        for_each = options_list.value.scheduling != null ? [options_list.value.scheduling] : []
        content {
          timezone = scheduling.value.timezone
          dynamic "timeframes" {
            for_each = scheduling.value.timeframes
            content {
              day  = timeframes.value.day
              from = timeframes.value.from
              to   = timeframes.value.to
            }
          }
        }
      }

      dynamic "rum_settings" {
        for_each = options_list.value.rum_settings != null ? [options_list.value.rum_settings] : []
        content {
          is_enabled      = rum_settings.value.is_enabled
          application_id  = rum_settings.value.application_id
          client_token_id = rum_settings.value.client_token_id
        }
      }

      dynamic "ci" {
        for_each = options_list.value.ci != null ? [options_list.value.ci] : []
        content {
          execution_rule = ci.value.execution_rule
        }
      }
    }
  }

  ###########################
  # API Steps (subtype=multi)
  ###########################
  dynamic "api_step" {
    for_each = each.value.api_step
    content {
      name              = api_step.value.name
      subtype           = api_step.value.subtype
      is_critical       = api_step.value.is_critical
      allow_failure     = api_step.value.allow_failure
      exit_if_succeed   = api_step.value.exit_if_succeed
      subtest_public_id = api_step.value.subtest_public_id

      dynamic "request_definition" {
        for_each = api_step.value.request_definition != null ? [api_step.value.request_definition] : []
        content {
          method                  = request_definition.value.method
          url                     = request_definition.value.url
          host                    = request_definition.value.host
          port                    = request_definition.value.port
          body                    = request_definition.value.body
          body_type               = request_definition.value.body_type
          timeout                 = request_definition.value.timeout
          call_type               = request_definition.value.call_type
          service                 = request_definition.value.service
          message                 = request_definition.value.message
          plain_proto_file        = request_definition.value.plain_proto_file
          mcp_protocol_version    = request_definition.value.mcp_protocol_version
          no_saving_response_body = request_definition.value.no_saving_response_body
        }
      }

      request_headers  = api_step.value.request_headers
      request_query    = api_step.value.request_query
      request_metadata = api_step.value.request_metadata

      dynamic "request_basicauth" {
        for_each = api_step.value.request_basicauth != null ? [api_step.value.request_basicauth] : []
        content {
          type                     = request_basicauth.value.type
          username                 = request_basicauth.value.username
          password                 = request_basicauth.value.password
          access_token_url         = request_basicauth.value.access_token_url
          token_api_authentication = request_basicauth.value.token_api_authentication
          client_id                = request_basicauth.value.client_id
          client_secret            = request_basicauth.value.client_secret
          resource                 = request_basicauth.value.resource
          scope                    = request_basicauth.value.scope
          audience                 = request_basicauth.value.audience
          workstation              = request_basicauth.value.workstation
          domain                   = request_basicauth.value.domain
        }
      }

      dynamic "request_client_certificate" {
        for_each = api_step.value.request_client_certificate != null ? [api_step.value.request_client_certificate] : []
        content {
          dynamic "cert" {
            for_each = request_client_certificate.value.cert != null ? [request_client_certificate.value.cert] : []
            content {
              content  = cert.value.content
              filename = cert.value.filename
            }
          }
          dynamic "key" {
            for_each = request_client_certificate.value.key != null ? [request_client_certificate.value.key] : []
            content {
              content  = key.value.content
              filename = key.value.filename
            }
          }
        }
      }

      dynamic "request_proxy" {
        for_each = api_step.value.request_proxy != null ? [api_step.value.request_proxy] : []
        content {
          url     = request_proxy.value.url
          headers = request_proxy.value.headers
        }
      }

      dynamic "assertion" {
        for_each = api_step.value.assertions
        content {
          type     = assertion.value.type
          operator = assertion.value.operator
          target   = assertion.value.target
          property = assertion.value.property

          dynamic "target_mcp_capabilities" {
            for_each = assertion.value.target_mcp_capabilities != null ? [assertion.value.target_mcp_capabilities] : []
            content {
              capabilities = target_mcp_capabilities.value.capabilities
            }
          }
        }
      }

      dynamic "extracted_value" {
        for_each = api_step.value.extracted_values
        content {
          name   = extracted_value.value.name
          type   = extracted_value.value.type
          field  = extracted_value.value.field
          secure = extracted_value.value.secure

          dynamic "parser" {
            for_each = extracted_value.value.parser != null ? [extracted_value.value.parser] : []
            content {
              type  = parser.value.type
              value = parser.value.value
            }
          }
        }
      }
    }
  }

  ###########################
  # Browser Steps (type=browser)
  ###########################
  dynamic "browser_step" {
    for_each = each.value.browser_step
    content {
      name                 = browser_step.value.name
      type                 = browser_step.value.type
      allow_failure        = browser_step.value.allow_failure
      always_execute       = browser_step.value.always_execute
      exit_if_succeed      = browser_step.value.exit_if_succeed
      force_element_update = browser_step.value.force_element_update
      is_critical          = browser_step.value.is_critical
      local_key            = browser_step.value.local_key
      no_screenshot        = browser_step.value.no_screenshot
      public_id            = browser_step.value.public_id
      timeout              = browser_step.value.timeout

      params {
        append_to_content     = browser_step.value.params.append_to_content
        attribute             = browser_step.value.params.attribute
        check                 = browser_step.value.params.check
        click_type            = browser_step.value.params.click_type
        click_with_javascript = browser_step.value.params.click_with_javascript
        code                  = browser_step.value.params.code
        delay                 = browser_step.value.params.delay
        element               = browser_step.value.params.element
        email                 = browser_step.value.params.email
        file                  = browser_step.value.params.file
        files                 = browser_step.value.params.files
        modifiers             = browser_step.value.params.modifiers
        playing_tab_id        = browser_step.value.params.playing_tab_id
        request               = browser_step.value.params.request
        requests              = browser_step.value.params.requests
        subtest_public_id     = browser_step.value.params.subtest_public_id
        value                 = browser_step.value.params.value
        with_click            = browser_step.value.params.with_click
        x                     = browser_step.value.params.x
        y                     = browser_step.value.params.y

        dynamic "element_user_locator" {
          for_each = browser_step.value.params.element_user_locator != null ? [browser_step.value.params.element_user_locator] : []
          iterator = eul
          content {
            fail_test_on_cannot_locate = eul.value.fail_test_on_cannot_locate
            value {
              type  = eul.value.locator_value.type
              value = eul.value.locator_value.value
            }
          }
        }

        dynamic "pattern" {
          for_each = browser_step.value.params.pattern != null ? [browser_step.value.params.pattern] : []
          iterator = ptn
          content {
            type  = ptn.value.type
            value = ptn.value.value
          }
        }

        dynamic "variable" {
          for_each = browser_step.value.params.step_variable != null ? [browser_step.value.params.step_variable] : []
          iterator = step_var
          content {
            name    = step_var.value.name
            example = step_var.value.example
            secure  = step_var.value.secure
          }
        }
      }
    }
  }

  ###########################
  # Browser Variables (type=browser)
  ###########################
  dynamic "browser_variable" {
    for_each = each.value.browser_variable
    content {
      name    = browser_variable.value.name
      type    = browser_variable.value.type
      example = browser_variable.value.example
      id      = browser_variable.value.id
      pattern = browser_variable.value.pattern
    }
  }

  ###########################
  # Config Variables
  ###########################
  dynamic "config_variable" {
    for_each = each.value.config_variable
    content {
      name    = config_variable.value.name
      type    = config_variable.value.type
      id      = config_variable.value.id
      pattern = config_variable.value.pattern
      example = config_variable.value.example
    }
  }
}
