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

<h3 align="center">Datadog Synthetics Global Variable</h3>
  <p align="center">
    Manages Datadog Synthetics global variables using a scalable map/for_each pattern.
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

Manages `datadog_synthetics_global_variable` resources. Global variables in Datadog Synthetics can be reused across multiple tests and support freeform values, secure (hidden) values, multi-factor authentication (MFA)/time-based one-time password (TOTP) tokens, FIDO2 variables, and variables populated from test results via `parse_test_options`.

## Prerequisites

- A Datadog account with Synthetics enabled.
- A Datadog provider configured with an API key and Application key that has the `synthetics_write` permission.
- If using `parse_test_options`, the referenced Synthetics test must exist before this resource is created.

## Usage

### Simple Freeform Variable

```hcl
module "synthetics_global_variables" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/synthetics/global_variable"

  global_variables = {
    base_url = {
      name        = "BASE_URL"
      description = "Base URL for API tests"
      tags        = ["env:production", "team:platform"]
      value       = "https://api.example.com"
    }

    api_version = {
      name        = "API_VERSION"
      description = "Current API version"
      tags        = ["env:production"]
      value       = "v2"
    }
  }
}
```

### Secure Variable (Secret)

```hcl
module "synthetics_global_variables" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/synthetics/global_variable"

  global_variables = {
    api_token = {
      name        = "API_TOKEN"
      description = "API authentication token"
      tags        = ["env:production", "team:platform"]
      value       = "<YOUR_VALUE_HERE>"
      secure      = true
    }
  }
}
```

### Multi-Factor Authentication (Time-based One-time Password) Variable

```hcl
module "synthetics_global_variables" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/synthetics/global_variable"

  global_variables = {
    mfa_token = {
      name        = "MFA_TOKEN"
      description = "Time-based one-time password token for MFA login tests"
      tags        = ["env:production"]
      value       = "<TOTP_SEED_VALUE>"
      is_totp     = true
      options = {
        totp_parameters = {
          digits           = 6
          refresh_interval = 30
        }
      }
    }
  }
}
```

### Variable Parsed from Test Result

```hcl
module "synthetics_global_variables" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/synthetics/global_variable"

  global_variables = {
    auth_token = {
      name          = "AUTH_TOKEN"
      description   = "Authentication token extracted from login test response"
      tags          = ["env:production"]
      parse_test_id = "abc-123-def"
      parse_test_options = {
        type  = "http_body"
        parser = {
          type  = "json_path"
          value = "$.token"
        }
      }
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **Sensitive `value` field**: The `value` attribute can contain secrets (API tokens, passwords, etc.). When `secure = true`, Datadog hides the value in the UI and API responses. Regardless of `secure`, the value is stored in Terraform state — enable state encryption when managing secrets with this module.
- **`value_wo` / write-only support**: The Datadog provider supports a `value_wo` write-only attribute (Terraform >= 1.11 only; not currently supported in OpenTofu). To use write-only values, set `value_wo_version` to trigger updates, and pass `value_wo` directly to the underlying resource. This module exposes `value_wo_version` to control update triggering. To use `value_wo`, consume the `datadog_synthetics_global_variable` resource directly until OpenTofu adds write-only attribute support.
- **`restricted_roles` deprecated**: This field is deprecated by the Datadog API. Use a `datadog_restriction_policy` resource instead.
- **Name format**: Global variable names must be all uppercase with underscores (e.g., `MY_VARIABLE`). Datadog enforces this constraint.
- **`is_totp` / `is_fido`**: Setting either to `true` automatically sets `secure = true` at the API level.
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
| [datadog_synthetics_global_variable.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/synthetics_global_variable) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_global_variables"></a> [global\_variables](#input\_global\_variables) | Map of Synthetics global variable configurations keyed by logical name. The 'value' field may contain sensitive data — enable Terraform state encryption when storing secrets. | <pre>map(object({<br/>    name             = string<br/>    description      = optional(string, "")<br/>    tags             = optional(list(string), [])<br/>    value            = optional(string, null)<br/>    value_wo_version = optional(string, null)<br/>    secure           = optional(bool, false)<br/>    is_totp          = optional(bool, false)<br/>    is_fido          = optional(bool, false)<br/>    restricted_roles = optional(set(string), null)<br/>    parse_test_id    = optional(string, null)<br/><br/>    options = optional(object({<br/>      totp_parameters = optional(object({<br/>        digits           = number<br/>        refresh_interval = number<br/>      }), null)<br/>    }), null)<br/><br/>    parse_test_options = optional(object({<br/>      type                = string<br/>      field               = optional(string, null)<br/>      local_variable_name = optional(string, null)<br/>      parser = optional(object({<br/>        type  = string<br/>        value = optional(string, null)<br/>      }), null)<br/>    }), null)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of global variable IDs keyed by logical name. |
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
