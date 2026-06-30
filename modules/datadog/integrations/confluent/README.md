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

<h3 align="center">Datadog Confluent Cloud Integration</h3>
  <p align="center">
    This module manages Datadog - Confluent Cloud account and resource integrations. It registers Confluent accounts with Datadog and links individual Confluent resources (Kafka clusters, connectors, Schema Registry, ksqlDB) for metrics collection.
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

- A Confluent Cloud account with an API key and secret. The API key must have MetricsViewer and ResourceViewer permissions.
- Resource IDs for each Confluent resource you want to monitor.

## Usage

### Complete Example

```hcl
module "datadog_confluent" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/confluent"

  confluent_accounts = {
    main = {
      api_key    = "<YOUR_CONFLUENT_API_KEY>"
      api_secret = "<YOUR_CONFLUENT_API_SECRET>"
      tags       = ["env:prod", "team:data"]
    }
  }

  confluent_resources = {
    kafka_prod = {
      account_id            = "<CONFLUENT_ACCOUNT_ID_FROM_OUTPUT>"
      resource_id           = "lkc-abc123"
      resource_type         = "kafka"
      enable_custom_metrics = true
      tags                  = ["env:prod"]
    }
    schema_registry = {
      account_id    = "<CONFLUENT_ACCOUNT_ID_FROM_OUTPUT>"
      resource_id   = "lsrc-xyz789"
      resource_type = "schema_registry"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `required_version = ">= 1.3.0"` — uses `optional()` with defaults inside object types, which requires Terraform/OpenTofu 1.3.0+. The Datadog provider itself mandates >= 1.1.5.
- `confluent_accounts` contains sensitive fields (`api_key`, `api_secret`). The variable is not marked `sensitive = true` (doing so would prevent `for_each` on the resource), so callers should pass these values via an environment variable (`TF_VAR_confluent_accounts`), Terraform Cloud/HCP sensitive variables, or a secrets manager integration rather than in plain-text `.tfvars` files.
- Valid `resource_type` values: `kafka`, `connector`, `ksql`, `schema_registry`.
- `enable_custom_metrics` defaults to `false`. When enabled, the `custom.consumer_lag_offset` metric is collected with additional tags (increases cardinality and may increase cost).
- The `account_id` in `confluent_resources` should reference the ID output from a `confluent_accounts` entry. Use `module.<name>.confluent_account_ids["<key>"]`.

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
| [datadog_integration_confluent_account.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_confluent_account) | resource |
| [datadog_integration_confluent_resource.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_confluent_resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_confluent_accounts"></a> [confluent\_accounts](#input\_confluent\_accounts) | Map of Confluent Cloud account integrations keyed by a logical name. Each entry registers one Confluent account with Datadog. The api\_key and api\_secret are sensitive. | <pre>map(object({<br/>    api_key    = string<br/>    api_secret = string<br/>    tags       = optional(set(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_confluent_resources"></a> [confluent\_resources](#input\_confluent\_resources) | Map of Confluent Cloud resource integrations keyed by a logical name. Each entry links one Confluent resource (Kafka cluster, connector, etc.) to a registered Confluent account. | <pre>map(object({<br/>    account_id            = string<br/>    resource_id           = string<br/>    resource_type         = optional(string)<br/>    enable_custom_metrics = optional(bool, false)<br/>    tags                  = optional(set(string))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_confluent_account_ids"></a> [confluent\_account\_ids](#output\_confluent\_account\_ids) | Map of Confluent account integration IDs keyed by logical name. |
| <a name="output_confluent_resource_ids"></a> [confluent\_resource\_ids](#output\_confluent\_resource\_ids) | Map of Confluent resource integration IDs keyed by logical name. |
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
