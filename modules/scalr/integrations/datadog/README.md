<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Datadog Integration Module</h3>
  <p align="center">
    This module manages <code>scalr_datadog_integration</code> resources in Scalr, connecting Scalr to Datadog so run metrics and events can be sent to a Datadog site.
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
    <li><a href="#usage">Usage</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#Resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- USAGE EXAMPLES -->
## Usage

### Prerequisites

- Scalr provider `>= 3.20.0`. The `scalr_datadog_integration` resource first shipped in that release.
- A Datadog API key for each integration. Never commit the key; pass it in from a secret store or a sensitive variable.
- A Scalr instance that supports Datadog integrations. The provider's v3.20.0 release notes do not yet state a minimum Scalr server version, so confirm support before applying against a live instance.

### Simple Example

```hcl
variable "datadog_api_key" {
  description = "Datadog API key used by the Scalr integration."
  type        = string
  sensitive   = true
}

module "datadog_integration" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/integrations/datadog"

  datadog_integrations = {
    primary = {
      name           = "datadog"
      deployment_url = "https://us5.datadoghq.com"
    }
  }

  # Keyed by the same logical names as datadog_integrations.
  datadog_api_keys = {
    primary = var.datadog_api_key
  }
}
```

### Multiple Datadog Sites

```hcl
module "datadog_integrations" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/integrations/datadog"

  datadog_integrations = {
    us = {
      name           = "datadog-us"
      deployment_url = "https://us5.datadoghq.com"
    }
    eu = {
      name           = "datadog-eu"
      deployment_url = "https://api.datadoghq.eu"
    }
    # deployment_url omitted: Scalr uses https://api.datadoghq.com.
    default_site = {
      name = "datadog-default"
    }
  }

  datadog_api_keys = {
    us           = var.datadog_api_key_us
    eu           = var.datadog_api_key_eu
    default_site = var.datadog_api_key_default
  }
}

output "datadog_integration_ids" {
  value = module.datadog_integrations.ids
}
```

### Importing an Existing Integration

Existing integrations can be imported by ID (`in-<RANDOM STRING>`) into the module's resource address:

```shell
tofu import 'module.datadog_integration.scalr_datadog_integration.this["primary"]' in-xxxxxxxxxx
```

The API key is never returned by the Scalr API, so the first plan after an import shows the key as a pending in-place change until it is applied.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.20.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.20.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_datadog_integration.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_datadog_api_keys"></a> [datadog\_api\_keys](#input\_datadog\_api\_keys) | Map of sensitive Datadog API keys for var.datadog\_integrations, keyed by the same logical key.<br/>Kept in a separate, wholly `sensitive = true` variable so that var.datadog\_integrations itself<br/>can remain non-sensitive (required, since it is the for\_each source for<br/>scalr\_datadog\_integration.this). Every key in var.datadog\_integrations must have a non-empty<br/>entry here, because the underlying provider requires an API key for every integration.<br/>Entries without a matching integration are ignored.<br/><br/>Example:<br/>  datadog\_api\_keys = {<br/>    primary = var.datadog\_api\_key<br/>  } | `map(string)` | `{}` | no |
| <a name="input_datadog_integrations"></a> [datadog\_integrations](#input\_datadog\_integrations) | Map of Scalr Datadog integrations keyed by a caller-chosen logical name. Each entry manages<br/>one `scalr_datadog_integration` resource, which lets Scalr send run metrics and events to<br/>Datadog. The sensitive Datadog API key for each entry is intentionally NOT part of this<br/>variable -- see var.datadog\_api\_keys. Keeping it out of this map lets var.datadog\_integrations<br/>remain non-sensitive, which is required because it is this module's for\_each source<br/>(OpenTofu/Terraform disallow for\_each over a sensitive collection).<br/><br/>Fields:<br/>  - name:           (Required) Name of the Datadog integration. Must not be blank and must be<br/>                     at most 128 characters.<br/>  - deployment\_url: (Optional) URL of the Datadog site, for example<br/>                     "https://us5.datadoghq.com". Must start with "https://" and must not<br/>                     embed credentials. When unset, Scalr uses "https://api.datadoghq.com".<br/><br/>Example:<br/>  datadog\_integrations = {<br/>    primary = {<br/>      name           = "datadog"<br/>      deployment\_url = "https://us5.datadoghq.com"<br/>    }<br/>  } | <pre>map(object({<br/>    name           = string<br/>    deployment_url = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_ids"></a> [account\_ids](#output\_account\_ids) | Map of the Scalr account IDs (acc-<RANDOM STRING>) each Datadog integration belongs to, keyed by the same logical name used in var.datadog\_integrations. |
| <a name="output_err_messages"></a> [err\_messages](#output\_err\_messages) | Map of error messages reported by Scalr keyed by the same logical name used in var.datadog\_integrations. Only meaningful when the matching status is "failed". |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Datadog integration IDs (in-<RANDOM STRING>) keyed by the same logical name used in var.datadog\_integrations. |
| <a name="output_statuses"></a> [statuses](#output\_statuses) | Map of Scalr Datadog integration statuses ("active", "disabled", or "failed") keyed by the same logical name used in var.datadog\_integrations. Scalr sets "failed" when the integration cannot connect to Datadog. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **Secrets live in a separate sensitive map.** `datadog_integrations` stays non-sensitive so it can drive `for_each` (OpenTofu/Terraform refuse `for_each` over a sensitive collection). Each integration's API key is looked up by the same key from the wholly sensitive `datadog_api_keys` map, the same pattern as `modules/scalr/vcs_provider`.
- **Every integration must have a key.** A cross-variable validation on `datadog_api_keys` fails the plan, naming the missing keys, when an integration has no entry. Null, empty, and whitespace-only keys are rejected too. Surplus entries in `datadog_api_keys` are ignored. Cross-variable validation needs OpenTofu or Terraform `>= 1.9.0`.
- **No whole-object output.** Unlike some sibling modules, this module does not output the full `scalr_datadog_integration` objects because they carry the sensitive `api_key`. It outputs only the explicit non-sensitive projections `ids`, `statuses`, `err_messages`, and `account_ids`, keyed by the logical name.
- **No `account_id` input.** The provider exposes `account_id` as a read-only attribute that Scalr fills in, so it is available as the `account_ids` output instead of an input.
- **`deployment_url` validation.** When set, it must start with `https://`, include a host, and must not embed credentials (the value is not sensitive and would be stored in state and plan output in plain text). When unset, Scalr uses `https://api.datadoghq.com`.
- **Name limits.** `name` must not be blank and is limited to 128 characters, matching the provider schema.
- **Connection failures are warnings, not errors.** If Scalr cannot reach Datadog, the provider still creates the integration and reports `status = "failed"` plus a message. Use the `statuses` and `err_messages` outputs (or a `check` block in the calling configuration) to surface that.
- **API key rotation.** Changing a value in `datadog_api_keys` updates the integration in place. The Scalr API never returns the key, so drift in the key itself cannot be detected.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

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

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasaurus)
- [Brad Engberg](https://github.com/bradms98)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
