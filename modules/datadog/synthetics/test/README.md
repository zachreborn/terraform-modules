<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Datadog Synthetics Test</h3>
  <p align="center">
    Manages Datadog Synthetics tests (API, browser, and multistep) using a scalable map/for_each pattern.
    <br />
    <a href="https://github.com/zachreborn/terraform-modules"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://zacharyhill.co">Zachary Hill</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Report Bug</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#description">Description</a></li>
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Description

Manages `datadog_synthetics_test` resources. This module supports the full range of Datadog Synthetics test types:

- **API tests** (`type = "api"`) with subtypes: `http`, `ssl`, `tcp`, `dns`, `icmp`, `udp`, `websocket`, `grpc`
- **Multistep API tests** (`type = "api"`, `subtype = "multi"`) — multiple ordered API steps per test
- **Browser tests** (`type = "browser"`) — recorded browser interaction tests

All nested configuration blocks (request definitions, assertions, options, retry settings, monitor options, browser steps, API steps, and config variables) are supported via dynamic blocks.

## Prerequisites

- A Datadog account with Synthetics enabled.
- A Datadog provider configured with an API key and Application key that has the `synthetics_write` permission.
- For **private location tests**: a `datadog_synthetics_private_location` resource must exist and its ID must be passed in `locations`.
- For **global variable references** in `config_variable` blocks (`type = "global"`): the referenced `datadog_synthetics_global_variable` must exist.

## Usage

### API HTTP Test

```hcl
module "synthetics_tests" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/synthetics/test"

  tests = {
    api_uptime = {
      name      = "Uptime check — example.org"
      type      = "api"
      subtype   = "http"
      status    = "live"
      message   = "Notify @pagerduty"
      locations = ["aws:us-east-1", "aws:eu-west-1"]
      tags      = ["env:production", "team:platform"]

      request_definition = {
        method = "GET"
        url    = "https://www.example.org"
      }

      request_headers = {
        Content-Type = "application/json"
      }

      assertions = [
        {
          type     = "statusCode"
          operator = "is"
          target   = "200"
        },
        {
          type     = "responseTime"
          operator = "lessThan"
          target   = "2000"
        }
      ]

      options_list = {
        tick_every = 900

        retry = {
          count    = 2
          interval = 300
        }

        monitor_options = {
          renotify_interval = 120
        }
      }
    }
  }
}
```

### API SSL Test

```hcl
module "synthetics_ssl_tests" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/synthetics/test"

  tests = {
    ssl_check = {
      name      = "SSL Certificate Check — example.org"
      type      = "api"
      subtype   = "ssl"
      status    = "live"
      locations = ["aws:us-east-1"]
      tags      = ["env:production"]

      request_definition = {
        host = "example.org"
        port = "443"
      }

      assertions = [
        {
          type     = "certificate"
          operator = "isInMoreThan"
          target   = "30"
        }
      ]

      options_list = {
        tick_every         = 900
        accept_self_signed = false
      }
    }
  }
}
```

### Multistep API Test

```hcl
module "synthetics_multistep" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/synthetics/test"

  tests = {
    login_flow = {
      name      = "Login API flow"
      type      = "api"
      subtype   = "multi"
      status    = "live"
      locations = ["aws:us-east-1"]
      tags      = ["env:staging", "team:auth"]

      options_list = {
        tick_every = 3600
      }

      api_step = [
        {
          name    = "POST login"
          subtype = "http"

          request_definition = {
            method = "POST"
            url    = "https://api.example.org/login"
          }

          assertions = [
            {
              type     = "statusCode"
              operator = "is"
              target   = "200"
            }
          ]

          extracted_values = [
            {
              name  = "AUTH_TOKEN"
              type  = "http_body"
              parser = {
                type  = "json_path"
                value = "$.token"
              }
            }
          ]
        },
        {
          name    = "GET profile"
          subtype = "http"

          request_definition = {
            method = "GET"
            url    = "https://api.example.org/profile"
          }

          request_headers = {
            Authorization = "Bearer {{ AUTH_TOKEN }}"
          }

          assertions = [
            {
              type     = "statusCode"
              operator = "is"
              target   = "200"
            }
          ]
        }
      ]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **`assertions` vs `assertion`**: The variable uses `assertions` (plural list) to hold multiple assertion objects per test. Each entry in the list is rendered as a separate `assertion {}` block in the resource. This avoids naming conflicts with Terraform HCL keywords.
- **`api_step` list ordering**: The provider respects the order of `api_step` blocks. The list order in `api_step` determines step execution order. Use a list (not a map) to preserve ordering.
- **`browser_step.params.step_variable`**: The provider uses a nested `variable {}` block inside `params`. To avoid conflicts with the Terraform `variable` keyword, this module's input attribute is named `step_variable`, which maps to the `variable {}` block in the resource.
- **`browser_step.params.element_user_locator.locator_value`**: The provider uses a nested `value {}` block inside `element_user_locator` with `type` and `value` attributes. To avoid confusion with the `value` meta-attribute, this module's input attribute is named `locator_value`.
- **Sensitive request credentials**: The `request_basicauth.password`, `request_basicauth.client_secret`, and `request_client_certificate` fields may contain secrets. These are stored in Terraform state. Enable state encryption when using credential-bearing tests.
- **`monitor_id` output**: Each Synthetics test automatically creates a Datadog monitor. The `monitor_ids` output exposes these IDs so you can reference them (e.g., to create composite monitors).
- **Global variable deprecation**: Direct use of `{{ GLOBAL_VAR }}` in test URLs is deprecated as of provider v3.1.0. Use `config_variable` blocks with `type = "global"` and reference the variable by its local name instead.
- **`device_ids`**: Only applicable to browser tests. Valid values include `laptop_large`, `tablet`, `mobile_small`, `chrome.laptop_large`, `firefox.laptop_large`, etc.
- **required_version >= 1.3.0**: The two-argument `optional(type, default)` syntax used in `variables.tf` requires Terraform >= 1.3.0 or OpenTofu >= 1.6.0 (since OpenTofu 1.6.x >= 1.3.0). This matches the version floor used by the other Datadog modules in this library (`rum`, `monitors`, `cloud_cost`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_datadog"></a> [datadog](#requirement\_datadog) | >= 4.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_datadog"></a> [datadog](#provider\_datadog) | 4.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [datadog_synthetics_test.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/synthetics_test) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_tests"></a> [tests](#input\_tests) | Map of Synthetics test configurations keyed by logical name. May contain sensitive data (basic auth credentials, client certificates) — enable Terraform state encryption when using this module. | <pre>map(object({<br/>    name       = string<br/>    type       = string<br/>    subtype    = optional(string, null)<br/>    status     = optional(string, "live")<br/>    message    = optional(string, "")<br/>    locations  = list(string)<br/>    tags       = optional(list(string), [])<br/>    set_cookie = optional(string, null)<br/>    device_ids = optional(list(string), null)<br/><br/>    ###########################<br/>    # Request Configuration<br/>    ###########################<br/>    request_definition = optional(object({<br/>      method                  = optional(string, null)<br/>      url                     = optional(string, null)<br/>      host                    = optional(string, null)<br/>      port                    = optional(string, null)<br/>      body                    = optional(string, null)<br/>      body_type               = optional(string, null)<br/>      timeout                 = optional(number, null)<br/>      no_saving_response_body = optional(bool, null)<br/>      number_of_packets       = optional(number, null)<br/>      should_track_hops       = optional(bool, null)<br/>      persist_cookies         = optional(bool, null)<br/>      dns_server              = optional(string, null)<br/>      dns_server_port         = optional(number, null)<br/>      message                 = optional(string, null)<br/>      servername              = optional(string, null)<br/>      call_type               = optional(string, null)<br/>      service                 = optional(string, null)<br/>      plain_proto_file        = optional(string, null)<br/>      mcp_protocol_version    = optional(string, null)<br/>    }), null)<br/><br/>    request_headers  = optional(map(string), null)<br/>    request_query    = optional(map(string), null)<br/>    request_metadata = optional(map(string), null)<br/><br/>    request_basicauth = optional(object({<br/>      type                     = optional(string, null)<br/>      username                 = optional(string, null)<br/>      password                 = optional(string, null)<br/>      access_token_url         = optional(string, null)<br/>      token_api_authentication = optional(string, null)<br/>      client_id                = optional(string, null)<br/>      client_secret            = optional(string, null)<br/>      resource                 = optional(string, null)<br/>      scope                    = optional(string, null)<br/>      audience                 = optional(string, null)<br/>      workstation              = optional(string, null)<br/>      domain                   = optional(string, null)<br/>    }), null)<br/><br/>    request_client_certificate = optional(object({<br/>      cert = optional(object({<br/>        content  = string<br/>        filename = optional(string, null)<br/>      }), null)<br/>      key = optional(object({<br/>        content  = string<br/>        filename = optional(string, null)<br/>      }), null)<br/>    }), null)<br/><br/>    request_proxy = optional(object({<br/>      url     = string<br/>      headers = optional(map(string), null)<br/>    }), null)<br/><br/>    ###########################<br/>    # Assertions<br/>    ###########################<br/>    assertions = optional(list(object({<br/>      type     = string<br/>      operator = optional(string, null)<br/>      target   = optional(string, null)<br/>      property = optional(string, null)<br/>      target_mcp_capabilities = optional(object({<br/>        capabilities = list(string)<br/>      }), null)<br/>    })), [])<br/><br/>    ###########################<br/>    # Options<br/>    ###########################<br/>    options_list = optional(object({<br/>      tick_every                        = optional(number, null)<br/>      accept_self_signed                = optional(bool, null)<br/>      allow_insecure                    = optional(bool, null)<br/>      blocked_request_patterns          = optional(list(string), null)<br/>      check_certificate_revocation      = optional(bool, null)<br/>      disable_aia_intermediate_fetching = optional(bool, null)<br/>      disable_cors                      = optional(bool, null)<br/>      disable_csp                       = optional(bool, null)<br/>      follow_redirects                  = optional(bool, null)<br/>      http_version                      = optional(string, null)<br/>      ignore_server_certificate_error   = optional(bool, null)<br/>      initial_navigation_timeout        = optional(number, null)<br/>      min_failure_duration              = optional(number, null)<br/>      min_location_failed               = optional(number, null)<br/>      monitor_name                      = optional(string, null)<br/>      monitor_priority                  = optional(number, null)<br/>      no_screenshot                     = optional(bool, null)<br/>      restricted_roles                  = optional(list(string), null)<br/><br/>      retry = optional(object({<br/>        count    = optional(number, null)<br/>        interval = optional(number, null)<br/>      }), null)<br/><br/>      monitor_options = optional(object({<br/>        escalation_message       = optional(string, null)<br/>        notification_preset_name = optional(string, null)<br/>        renotify_interval        = optional(number, null)<br/>        renotify_occurrences     = optional(number, null)<br/>      }), null)<br/><br/>      scheduling = optional(object({<br/>        timezone = string<br/>        timeframes = list(object({<br/>          day  = number<br/>          from = string<br/>          to   = string<br/>        }))<br/>      }), null)<br/><br/>      rum_settings = optional(object({<br/>        is_enabled      = bool<br/>        application_id  = optional(string, null)<br/>        client_token_id = optional(number, null)<br/>      }), null)<br/><br/>      ci = optional(object({<br/>        execution_rule = string<br/>      }), null)<br/>    }), null)<br/><br/>    ###########################<br/>    # API Steps (subtype=multi)<br/>    ###########################<br/>    api_step = optional(list(object({<br/>      name              = string<br/>      subtype           = string<br/>      is_critical       = optional(bool, null)<br/>      allow_failure     = optional(bool, null)<br/>      exit_if_succeed   = optional(bool, null)<br/>      subtest_public_id = optional(string, null)<br/><br/>      request_definition = optional(object({<br/>        method                  = optional(string, null)<br/>        url                     = optional(string, null)<br/>        host                    = optional(string, null)<br/>        port                    = optional(string, null)<br/>        body                    = optional(string, null)<br/>        body_type               = optional(string, null)<br/>        timeout                 = optional(number, null)<br/>        call_type               = optional(string, null)<br/>        service                 = optional(string, null)<br/>        message                 = optional(string, null)<br/>        plain_proto_file        = optional(string, null)<br/>        mcp_protocol_version    = optional(string, null)<br/>        no_saving_response_body = optional(bool, null)<br/>      }), null)<br/><br/>      request_headers  = optional(map(string), null)<br/>      request_query    = optional(map(string), null)<br/>      request_metadata = optional(map(string), null)<br/><br/>      request_basicauth = optional(object({<br/>        type                     = optional(string, null)<br/>        username                 = optional(string, null)<br/>        password                 = optional(string, null)<br/>        access_token_url         = optional(string, null)<br/>        token_api_authentication = optional(string, null)<br/>        client_id                = optional(string, null)<br/>        client_secret            = optional(string, null)<br/>        resource                 = optional(string, null)<br/>        scope                    = optional(string, null)<br/>        audience                 = optional(string, null)<br/>        workstation              = optional(string, null)<br/>        domain                   = optional(string, null)<br/>      }), null)<br/><br/>      request_client_certificate = optional(object({<br/>        cert = optional(object({<br/>          content  = string<br/>          filename = optional(string, null)<br/>        }), null)<br/>        key = optional(object({<br/>          content  = string<br/>          filename = optional(string, null)<br/>        }), null)<br/>      }), null)<br/><br/>      request_proxy = optional(object({<br/>        url     = string<br/>        headers = optional(map(string), null)<br/>      }), null)<br/><br/>      assertions = optional(list(object({<br/>        type     = string<br/>        operator = optional(string, null)<br/>        target   = optional(string, null)<br/>        property = optional(string, null)<br/>        target_mcp_capabilities = optional(object({<br/>          capabilities = list(string)<br/>        }), null)<br/>      })), [])<br/><br/>      extracted_values = optional(list(object({<br/>        name   = string<br/>        type   = string<br/>        field  = optional(string, null)<br/>        secure = optional(bool, null)<br/>        parser = optional(object({<br/>          type  = string<br/>          value = optional(string, null)<br/>        }), null)<br/>      })), [])<br/>    })), [])<br/><br/>    ###########################<br/>    # Browser Steps (type=browser)<br/>    ###########################<br/>    browser_step = optional(list(object({<br/>      name                 = string<br/>      type                 = string<br/>      allow_failure        = optional(bool, null)<br/>      always_execute       = optional(bool, null)<br/>      exit_if_succeed      = optional(bool, null)<br/>      force_element_update = optional(bool, null)<br/>      is_critical          = optional(bool, null)<br/>      local_key            = optional(string, null)<br/>      no_screenshot        = optional(bool, null)<br/>      public_id            = optional(string, null)<br/>      timeout              = optional(number, null)<br/><br/>      params = object({<br/>        append_to_content     = optional(string, null)<br/>        attribute             = optional(string, null)<br/>        check                 = optional(string, null)<br/>        click_type            = optional(string, null)<br/>        click_with_javascript = optional(bool, null)<br/>        code                  = optional(string, null)<br/>        delay                 = optional(number, null)<br/>        element               = optional(string, null)<br/>        email                 = optional(string, null)<br/>        file                  = optional(string, null)<br/>        files                 = optional(string, null)<br/>        modifiers             = optional(list(string), null)<br/>        playing_tab_id        = optional(string, null)<br/>        request               = optional(string, null)<br/>        requests              = optional(string, null)<br/>        subtest_public_id     = optional(string, null)<br/>        value                 = optional(string, null)<br/>        with_click            = optional(bool, null)<br/>        x                     = optional(number, null)<br/>        y                     = optional(number, null)<br/><br/>        element_user_locator = optional(object({<br/>          fail_test_on_cannot_locate = optional(bool, null)<br/>          locator_value = object({<br/>            type  = string<br/>            value = string<br/>          })<br/>        }), null)<br/><br/>        pattern = optional(object({<br/>          type  = string<br/>          value = string<br/>        }), null)<br/><br/>        step_variable = optional(object({<br/>          name    = string<br/>          example = optional(string, null)<br/>          secure  = optional(bool, null)<br/>        }), null)<br/>      })<br/>    })), [])<br/><br/>    ###########################<br/>    # Browser Variables (type=browser)<br/>    ###########################<br/>    browser_variable = optional(list(object({<br/>      name    = string<br/>      type    = string<br/>      example = optional(string, null)<br/>      id      = optional(string, null)<br/>      pattern = optional(string, null)<br/>    })), [])<br/><br/>    ###########################<br/>    # Config Variables<br/>    ###########################<br/>    config_variable = optional(list(object({<br/>      name    = string<br/>      type    = string<br/>      id      = optional(string, null)<br/>      pattern = optional(string, null)<br/>      example = optional(string, null)<br/>    })), [])<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Synthetics test IDs keyed by logical name. |
| <a name="output_monitor_ids"></a> [monitor\_ids](#output\_monitor\_ids) | Map of Datadog monitor IDs associated with each Synthetics test, keyed by logical name. |
<!-- END_TF_DOCS -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Acknowledgments

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasarus)
- [Brad Engberg](https://github.com/bradms98)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/zachreborn/terraform-modules.svg?style=for-the-badge
[contributors-url]: https://github.com/zachreborn/terraform-modules/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/zachreborn/terraform-modules.svg?style=for-the-badge
[forks-url]: https://github.com/zachreborn/terraform-modules/network/members
[stars-shield]: https://img.shields.io/github/stars/zachreborn/terraform-modules.svg?style=for-the-badge
[stars-url]: https://github.com/zachreborn/terraform-modules/stargazers
[issues-shield]: https://img.shields.io/github/issues/zachreborn/terraform-modules.svg?style=for-the-badge
[issues-url]: https://github.com/zachreborn/terraform-modules/issues
[license-shield]: https://img.shields.io/github/license/zachreborn/terraform-modules.svg?style=for-the-badge
[license-url]: https://github.com/zachreborn/terraform-modules/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
