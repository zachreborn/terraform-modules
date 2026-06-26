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

<h3 align="center">Datadog Monitor Notification Rule</h3>
  <p align="center">
    Manages Datadog monitor notification rules (datadog_monitor_notification_rule) for routing monitor alerts to specific recipients based on tags or scopes.
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
    <li><a href="#modules">Modules</a></li>
    <li><a href="#Resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Description

This module manages one or more [Datadog monitor notification rules](https://docs.datadoghq.com/monitors/notify/notification_rules/) (`datadog_monitor_notification_rule`). Notification rules allow you to route monitor alert notifications to different recipients based on monitor tags or scope conditions — for example, routing all `team:checkout` monitor alerts to a specific Slack channel and PagerDuty service.

Two routing modes are supported:
- **Simple routing** (`recipients`): Send all matching monitor notifications to a fixed list of recipients.
- **Conditional routing** (`conditional_recipients`): Route to different recipients based on monitor attributes such as priority or environment.

## Prerequisites

- A Datadog account with an API key and Application key configured in the provider.
- The Datadog Terraform provider (`DataDog/datadog >= 4.0.0`) configured in the calling module or root.

## Usage

### Simple tag-based routing

```hcl
module "notification_rules" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/monitors/notification_rule"

  notification_rules = {
    checkout_team = {
      name       = "Route alerts from checkout team"
      recipients = ["slack-checkout-ops", "jira-checkout"]
      filter = {
        tags = ["team:checkout"]
      }
    }
  }
}
```

### Scope-based routing with conditional recipients

```hcl
module "notification_rules" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/monitors/notification_rule"

  notification_rules = {
    payment_team_routing = {
      name = "Routing logic for team payment"
      filter = {
        scope = "team:payment AND NOT env:dev AND service:(payment-processing OR payment-gateway)"
      }
      conditional_recipients = {
        conditions = [
          {
            scope      = "priority:p1"
            recipients = ["oncall-payment", "slack-payment"]
          },
          {
            scope      = "priority:p5"
            recipients = ["slack-payment"]
          }
        ]
        fallback_recipients = ["slack-payment"]
      }
    }
  }
}
```

### Multiple rules for different teams

```hcl
module "notification_rules" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/monitors/notification_rule"

  notification_rules = {
    platform_team = {
      name       = "Route platform team alerts"
      recipients = ["slack-platform-alerts", "pagerduty-platform"]
      filter = {
        tags = ["team:platform"]
      }
    }
    data_team = {
      name       = "Route data team alerts"
      recipients = ["slack-data-alerts"]
      filter = {
        tags = ["team:data"]
      }
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **`required_version >= 1.1.5`**: The Datadog provider requires Terraform/OpenTofu 1.1.5+ to support certain provider features. This is stricter than the default `>= 1.0.0` used in AWS modules.
- **`filter` is required**: The Datadog provider enforces (`objectvalidator.IsRequired()`) that every notification rule must include a `filter` block. A notification rule without a filter would implicitly match all monitors, which the API disallows.
- **`filter.scope` and `filter.tags` are mutually exclusive**: Exactly one of `scope` or `tags` must be set in the `filter` block (enforced by both the provider's `ConfigValidators` and a module validation block). `scope` accepts a boolean expression (e.g., `team:payment AND NOT env:dev`); `tags` accepts a list of `key:value` pairs with AND semantics.
- **Exactly one of `recipients` or `conditional_recipients` must be set**: Both being present or both being absent will fail provider validation. The module validates this at plan time.
- **Recipient format**: Recipients use the same `@<handle>` format as Datadog monitor messages, but without the leading `@` (e.g., `"slack-my-channel"` instead of `"@slack-my-channel"`).
- **Condition `scope` format**: Condition scopes support `transition_type:<value>` (e.g., `transition_type:is_alert`) or single `key:value` tag pairs (e.g., `priority:p1`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.5 |
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
| [datadog_monitor_notification_rule.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/monitor_notification_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_notification_rules"></a> [notification\_rules](#input\_notification\_rules) | Map of Datadog monitor notification rule configurations keyed by logical name. Each entry maps to one datadog\_monitor\_notification\_rule resource. | <pre>map(object({<br/>    ###########################<br/>    # Required Fields<br/>    ###########################<br/>    name = string<br/><br/>    ###########################<br/>    # Optional Fields<br/>    ###########################<br/>    # Exactly one of recipients or conditional_recipients must be set.<br/>    # Use recipients for simple routing; use conditional_recipients for conditional routing.<br/>    recipients = optional(set(string), null)<br/><br/>    ###########################<br/>    # filter Block (Required)<br/>    ###########################<br/>    # Specifies which monitors this rule applies to.<br/>    # Exactly one of scope or tags must be set within the filter block.<br/>    filter = object({<br/>      scope = optional(string, null)<br/>      tags  = optional(set(string), null)<br/>    })<br/><br/>    ###########################<br/>    # conditional_recipients Block<br/>    ###########################<br/>    # Cannot be used with recipients.<br/>    conditional_recipients = optional(object({<br/>      fallback_recipients = optional(set(string), null)<br/>      conditions = optional(list(object({<br/>        scope      = string<br/>        recipients = set(string)<br/>      })), null)<br/>    }), null)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of notification rule logical names to their Datadog notification rule IDs. |
| <a name="output_notification_rules"></a> [notification\_rules](#output\_notification\_rules) | Full map of all datadog\_monitor\_notification\_rule resource objects, keyed by logical name. |
<!-- END_TF_DOCS -->

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

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
[product-screenshot]: /images/screenshot.webp
[Terraform.io]: https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform
[Terraform-url]: https://terraform.io
