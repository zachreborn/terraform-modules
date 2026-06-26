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

<h3 align="center">Datadog GCP Integration (STS)</h3>
  <p align="center">
    This module manages Datadog - Google Cloud Platform integrations using the STS (Service-to-Service) authentication method. Each entry in the map registers one GCP service account with Datadog for metrics, resource, and security data collection.
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

- A Google Cloud Platform service account with the following roles:
  - `roles/compute.viewer`
  - `roles/monitoring.viewer`
  - `roles/cloudasset.viewer`
  - `roles/browser` (required in the default project of the service account only)
- After running this module, you must grant `roles/iam.serviceAccountTokenCreator` to the Datadog delegate service account email (available in the `delegate_account_emails` output) on the GCP service account. This cannot be automated within this module because the delegate email is only known after `apply`.
- GCP service account provisioning is outside the scope of this module. Use a GCP Terraform provider or the GCP console.

## Usage

### Simple Example

```hcl
module "datadog_gcp" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/gcp"

  gcp_accounts = {
    prod_project = {
      client_email          = "datadog-integration@my-gcp-project.iam.gserviceaccount.com"
      account_tags          = ["env:prod", "project:my-gcp-project"]
      automute              = true
      is_cspm_enabled       = true
      resource_collection_enabled = true
    }
  }
}

# After apply, grant the token creator role to the delegate:
# resource "google_service_account_iam_member" "datadog_sts" {
#   service_account_id = google_service_account.datadog.name
#   role               = "roles/iam.serviceAccountTokenCreator"
#   member             = "serviceAccount:${module.datadog_gcp.delegate_account_emails["prod_project"]}"
# }
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `required_version = ">= 1.3.0"` — uses `optional()` with defaults inside object types, which requires Terraform/OpenTofu 1.3.0+. The Datadog provider itself mandates >= 1.1.5.
- This module uses `datadog_integration_gcp_sts` (the STS-based integration), NOT the deprecated `datadog_integration_gcp`. The STS method is the current recommended approach.
- The `delegate_account_email` is a computed (read-only) attribute from Datadog that you must use to configure IAM on your GCP service account. It is exposed in the `delegate_account_emails` output.
- `is_cspm_enabled` requires `resource_collection_enabled = true`.
- `cloud_run_revision_filters` and `host_filters` attributes exist in the provider but are deprecated. Use `monitored_resource_configs` for filtering instead.
- `is_security_command_center_enabled` requires additional IAM permissions on the service account. Defaults to `false`.

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
| [datadog_integration_gcp_sts.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_gcp_sts) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_gcp_accounts"></a> [gcp\_accounts](#input\_gcp\_accounts) | Map of Google Cloud Platform account integrations keyed by a logical name. Each entry creates one Datadog - GCP STS integration for a service account. | <pre>map(object({<br/>    client_email                          = string<br/>    account_tags                          = optional(set(string))<br/>    automute                              = optional(bool)<br/>    is_cspm_enabled                       = optional(bool)<br/>    is_global_location_enabled            = optional(bool)<br/>    is_per_project_quota_enabled          = optional(bool)<br/>    is_resource_change_collection_enabled = optional(bool)<br/>    is_security_command_center_enabled    = optional(bool, false)<br/>    resource_collection_enabled           = optional(bool)<br/>    region_filter_configs                 = optional(set(string))<br/>    metric_namespace_configs = optional(list(object({<br/>      id       = optional(string)<br/>      disabled = optional(bool)<br/>      filters  = optional(set(string))<br/>    })))<br/>    monitored_resource_configs = optional(list(object({<br/>      type    = optional(string)<br/>      filters = optional(set(string))<br/>    })))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_delegate_account_emails"></a> [delegate\_account\_emails](#output\_delegate\_account\_emails) | Map of Datadog STS delegate service account emails keyed by logical name. Use these to grant the token creator role in GCP. |
| <a name="output_gcp_account_ids"></a> [gcp\_account\_ids](#output\_gcp\_account\_ids) | Map of GCP integration IDs keyed by logical name. |
<!-- END_TF_DOCS -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Acknowledgments

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)

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
