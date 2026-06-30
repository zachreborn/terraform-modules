[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Datadog Webhook Integration</h3>
  <p align="center">
    This module manages Datadog webhooks and webhook custom variables. Webhooks allow Datadog monitors to send HTTP POST requests to any endpoint when alerts trigger — enabling integrations with Jira, Atlassian Statuspage, PagerDuty, or any custom HTTP endpoint.
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
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Prerequisites

- The target HTTP endpoint must be reachable from Datadog's servers.
- For Atlassian Jira or Statuspage integrations, the webhook URL and any required API tokens should be stored as `webhook_custom_variables` with `is_secret = true`.

## Usage

### Jira/Statuspage Webhook Example

```hcl
module "datadog_webhooks" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/webhook"

  webhooks = {
    jira_create_issue = {
      name      = "JIRA-create-issue"
      url       = "https://yourcompany.atlassian.net/rest/api/2/issue"
      encode_as = "json"
      custom_headers = jsonencode({
        "Authorization" = "Basic $JIRA_TOKEN"
        "Content-Type"  = "application/json"
      })
      payload = jsonencode({
        fields = {
          project    = { key = "OPS" }
          summary    = "$EVENT_TITLE"
          issuetype  = { name = "Bug" }
          description = "$EVENT_MSG"
        }
      })
    }
  }

  webhook_custom_variables = {
    jira_token = {
      name      = "JIRA_TOKEN"
      value     = "<YOUR_BASE64_ENCODED_JIRA_API_TOKEN>"
      is_secret = true
    }
  }
}
```

### Generic Webhook Example

```hcl
module "datadog_webhooks" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/webhook"

  webhooks = {
    my_endpoint = {
      name      = "my-endpoint"
      url       = "https://hooks.example.com/datadog"
      encode_as = "json"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `required_version = ">= 1.3.0"` — uses `optional()` with defaults inside object types, which requires Terraform/OpenTofu 1.3.0+. The Datadog provider itself mandates >= 1.1.5.
- **Atlassian integration path**: The Datadog provider has no native Atlassian (Jira, Statuspage) resource. This generic webhook module is the recommended way to wire Datadog monitors to Atlassian services. See also `modules/datadog/integrations/opsgenie` for Atlassian's Opsgenie alerting product.
- `encode_as` valid values: `json`, `form`. Defaults to `null` (Datadog uses JSON by default).
- `custom_headers` and `payload` accept JSON-encoded strings. Use `jsonencode()` in the calling configuration for readability.
- `webhook_custom_variables` contains a sensitive field (`value`). The variable is not marked `sensitive = true` (doing so would prevent `for_each` on the resource), so callers should pass secret values via an environment variable (`TF_VAR_webhook_custom_variables`), Terraform Cloud/HCP sensitive variables, or a secrets manager integration rather than in plain-text `.tfvars` files. Custom variable names are referenced in webhook URLs/payloads as `$VARIABLE_NAME`.

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
| [datadog_webhook.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/webhook) | resource |
| [datadog_webhook_custom_variable.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/webhook_custom_variable) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_webhook_custom_variables"></a> [webhook\_custom\_variables](#input\_webhook\_custom\_variables) | Map of Datadog webhook custom variables keyed by a logical name. Each entry creates one reusable variable that can be referenced in webhook URLs and payloads. The value is sensitive. | <pre>map(object({<br/>    name      = string<br/>    value     = string<br/>    is_secret = bool<br/>  }))</pre> | `{}` | no |
| <a name="input_webhooks"></a> [webhooks](#input\_webhooks) | Map of Datadog webhooks keyed by a logical name. Each entry creates one webhook that Datadog can call when a monitor alert triggers. | <pre>map(object({<br/>    name           = string<br/>    url            = string<br/>    custom_headers = optional(string)<br/>    encode_as      = optional(string)<br/>    payload        = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_webhook_custom_variable_ids"></a> [webhook\_custom\_variable\_ids](#output\_webhook\_custom\_variable\_ids) | Map of Datadog webhook custom variable IDs keyed by logical name. |
| <a name="output_webhook_ids"></a> [webhook\_ids](#output\_webhook\_ids) | Map of Datadog webhook IDs keyed by logical name. |
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
