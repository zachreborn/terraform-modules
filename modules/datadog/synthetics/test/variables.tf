###########################
# Resource Variables
###########################
variable "tests" {
  description = "Map of Synthetics test configurations keyed by logical name. May contain sensitive data (basic auth credentials, client certificates) — enable Terraform state encryption when using this module."
  type = map(object({
    name       = string
    type       = string
    subtype    = optional(string, null)
    status     = optional(string, "live")
    message    = optional(string, "")
    locations  = list(string)
    tags       = optional(list(string), [])
    set_cookie = optional(string, null)
    device_ids = optional(list(string), null)

    ###########################
    # Request Configuration
    ###########################
    request_definition = optional(object({
      method                  = optional(string, null)
      url                     = optional(string, null)
      host                    = optional(string, null)
      port                    = optional(string, null)
      body                    = optional(string, null)
      body_type               = optional(string, null)
      timeout                 = optional(number, null)
      no_saving_response_body = optional(bool, null)
      number_of_packets       = optional(number, null)
      should_track_hops       = optional(bool, null)
      persist_cookies         = optional(bool, null)
      dns_server              = optional(string, null)
      dns_server_port         = optional(number, null)
      message                 = optional(string, null)
      servername              = optional(string, null)
      call_type               = optional(string, null)
      service                 = optional(string, null)
      plain_proto_file        = optional(string, null)
      mcp_protocol_version    = optional(string, null)
    }), null)

    request_headers  = optional(map(string), null)
    request_query    = optional(map(string), null)
    request_metadata = optional(map(string), null)

    request_basicauth = optional(object({
      type                     = optional(string, null)
      username                 = optional(string, null)
      password                 = optional(string, null)
      access_token_url         = optional(string, null)
      token_api_authentication = optional(string, null)
      client_id                = optional(string, null)
      client_secret            = optional(string, null)
      resource                 = optional(string, null)
      scope                    = optional(string, null)
      audience                 = optional(string, null)
      workstation              = optional(string, null)
      domain                   = optional(string, null)
    }), null)

    request_client_certificate = optional(object({
      cert = optional(object({
        content  = string
        filename = optional(string, null)
      }), null)
      key = optional(object({
        content  = string
        filename = optional(string, null)
      }), null)
    }), null)

    request_proxy = optional(object({
      url     = string
      headers = optional(map(string), null)
    }), null)

    ###########################
    # Assertions
    ###########################
    assertions = optional(list(object({
      type     = string
      operator = optional(string, null)
      target   = optional(string, null)
      property = optional(string, null)
      target_mcp_capabilities = optional(object({
        capabilities = list(string)
      }), null)
    })), [])

    ###########################
    # Options
    ###########################
    options_list = optional(object({
      tick_every                        = optional(number, null)
      accept_self_signed                = optional(bool, null)
      allow_insecure                    = optional(bool, null)
      blocked_request_patterns          = optional(list(string), null)
      check_certificate_revocation      = optional(bool, null)
      disable_aia_intermediate_fetching = optional(bool, null)
      disable_cors                      = optional(bool, null)
      disable_csp                       = optional(bool, null)
      follow_redirects                  = optional(bool, null)
      http_version                      = optional(string, null)
      ignore_server_certificate_error   = optional(bool, null)
      initial_navigation_timeout        = optional(number, null)
      min_failure_duration              = optional(number, null)
      min_location_failed               = optional(number, null)
      monitor_name                      = optional(string, null)
      monitor_priority                  = optional(number, null)
      no_screenshot                     = optional(bool, null)
      restricted_roles                  = optional(list(string), null)

      retry = optional(object({
        count    = optional(number, null)
        interval = optional(number, null)
      }), null)

      monitor_options = optional(object({
        escalation_message       = optional(string, null)
        notification_preset_name = optional(string, null)
        renotify_interval        = optional(number, null)
        renotify_occurrences     = optional(number, null)
      }), null)

      scheduling = optional(object({
        timezone = string
        timeframes = list(object({
          day  = number
          from = string
          to   = string
        }))
      }), null)

      rum_settings = optional(object({
        is_enabled      = bool
        application_id  = optional(string, null)
        client_token_id = optional(number, null)
      }), null)

      ci = optional(object({
        execution_rule = string
      }), null)
    }), null)

    ###########################
    # API Steps (subtype=multi)
    ###########################
    api_step = optional(list(object({
      name              = string
      subtype           = string
      is_critical       = optional(bool, null)
      allow_failure     = optional(bool, null)
      exit_if_succeed   = optional(bool, null)
      subtest_public_id = optional(string, null)

      request_definition = optional(object({
        method                  = optional(string, null)
        url                     = optional(string, null)
        host                    = optional(string, null)
        port                    = optional(string, null)
        body                    = optional(string, null)
        body_type               = optional(string, null)
        timeout                 = optional(number, null)
        call_type               = optional(string, null)
        service                 = optional(string, null)
        message                 = optional(string, null)
        plain_proto_file        = optional(string, null)
        mcp_protocol_version    = optional(string, null)
        no_saving_response_body = optional(bool, null)
      }), null)

      request_headers  = optional(map(string), null)
      request_query    = optional(map(string), null)
      request_metadata = optional(map(string), null)

      request_basicauth = optional(object({
        type                     = optional(string, null)
        username                 = optional(string, null)
        password                 = optional(string, null)
        access_token_url         = optional(string, null)
        token_api_authentication = optional(string, null)
        client_id                = optional(string, null)
        client_secret            = optional(string, null)
        resource                 = optional(string, null)
        scope                    = optional(string, null)
        audience                 = optional(string, null)
        workstation              = optional(string, null)
        domain                   = optional(string, null)
      }), null)

      request_client_certificate = optional(object({
        cert = optional(object({
          content  = string
          filename = optional(string, null)
        }), null)
        key = optional(object({
          content  = string
          filename = optional(string, null)
        }), null)
      }), null)

      request_proxy = optional(object({
        url     = string
        headers = optional(map(string), null)
      }), null)

      assertions = optional(list(object({
        type     = string
        operator = optional(string, null)
        target   = optional(string, null)
        property = optional(string, null)
        target_mcp_capabilities = optional(object({
          capabilities = list(string)
        }), null)
      })), [])

      extracted_values = optional(list(object({
        name   = string
        type   = string
        field  = optional(string, null)
        secure = optional(bool, null)
        parser = optional(object({
          type  = string
          value = optional(string, null)
        }), null)
      })), [])
    })), [])

    ###########################
    # Browser Steps (type=browser)
    ###########################
    browser_step = optional(list(object({
      name                 = string
      type                 = string
      allow_failure        = optional(bool, null)
      always_execute       = optional(bool, null)
      exit_if_succeed      = optional(bool, null)
      force_element_update = optional(bool, null)
      is_critical          = optional(bool, null)
      local_key            = optional(string, null)
      no_screenshot        = optional(bool, null)
      public_id            = optional(string, null)
      timeout              = optional(number, null)

      params = object({
        append_to_content     = optional(string, null)
        attribute             = optional(string, null)
        check                 = optional(string, null)
        click_type            = optional(string, null)
        click_with_javascript = optional(bool, null)
        code                  = optional(string, null)
        delay                 = optional(number, null)
        element               = optional(string, null)
        email                 = optional(string, null)
        file                  = optional(string, null)
        files                 = optional(string, null)
        modifiers             = optional(list(string), null)
        playing_tab_id        = optional(string, null)
        request               = optional(string, null)
        requests              = optional(string, null)
        subtest_public_id     = optional(string, null)
        value                 = optional(string, null)
        with_click            = optional(bool, null)
        x                     = optional(number, null)
        y                     = optional(number, null)

        element_user_locator = optional(object({
          fail_test_on_cannot_locate = optional(bool, null)
          locator_value = object({
            type  = string
            value = string
          })
        }), null)

        pattern = optional(object({
          type  = string
          value = string
        }), null)

        step_variable = optional(object({
          name    = string
          example = optional(string, null)
          secure  = optional(bool, null)
        }), null)
      })
    })), [])

    ###########################
    # Browser Variables (type=browser)
    ###########################
    browser_variable = optional(list(object({
      name    = string
      type    = string
      example = optional(string, null)
      id      = optional(string, null)
      pattern = optional(string, null)
    })), [])

    ###########################
    # Config Variables
    ###########################
    config_variable = optional(list(object({
      name    = string
      type    = string
      id      = optional(string, null)
      pattern = optional(string, null)
      example = optional(string, null)
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.tests : contains(["api", "browser"], v.type)
    ])
    error_message = "type must be one of: api, browser."
  }

  validation {
    condition = alltrue([
      for k, v in var.tests :
      v.subtype == null || contains(["http", "ssl", "tcp", "dns", "icmp", "udp", "websocket", "grpc", "multi"], v.subtype)
    ])
    error_message = "subtype must be one of: http, ssl, tcp, dns, icmp, udp, websocket, grpc, multi."
  }

  validation {
    condition = alltrue([
      for k, v in var.tests : contains(["live", "paused"], v.status)
    ])
    error_message = "status must be one of: live, paused."
  }
}
