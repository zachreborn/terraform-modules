<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Wiz Integration Module</h3>
  <p align="center">
    This module manages <code>scalr_wiz_integration</code> resources in Scalr, connecting Scalr to Wiz so runs can be scanned with <code>wizcli</code> using a Wiz service account.
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

- Scalr provider `>= 3.20.0`. The `scalr_wiz_integration` resource first shipped in that release.
- A Wiz service account (client ID and client secret) for each integration. Never commit the secret; pass it in from a secret store or a sensitive variable.
- A Scalr instance that supports Wiz integrations. The provider's v3.20.0 release notes do not yet state a minimum Scalr server version, so confirm support before applying against a live instance.

### Simple Example

```hcl
variable "wiz_client_secret" {
  description = "Wiz service-account client secret used by the Scalr integration."
  type        = string
  sensitive   = true
}

module "wiz_integration" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/integrations/wiz"

  wiz_integrations = {
    iac_scanning = {
      name              = "wiz"
      client_id         = "svc-account-client-id"
      default_policies  = ["Default IaC policy"]
      default_scan_name = "scalr-iac-scan"
      endpoint_mode     = "commercial"
      autofail          = false
      environments      = ["env-xxxxxxxxxx"] # or ["*"] for all environments
    }
  }

  # Keyed by the same logical names as wiz_integrations.
  wiz_client_secrets = {
    iac_scanning = var.wiz_client_secret
  }
}
```

### Multiple Wiz Tenants

```hcl
module "wiz_integrations" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/integrations/wiz"

  wiz_integrations = {
    commercial = {
      name         = "wiz-commercial"
      client_id    = "commercial-client-id"
      environments = ["*"] # all current and future environments
    }
    govcloud = {
      name          = "wiz-govcloud"
      client_id     = "govcloud-client-id"
      endpoint_mode = "govcloud"
      autofail      = true
      environments  = ["env-xxxxxxxxxx", "env-yyyyyyyyyy"]
    }
  }

  wiz_client_secrets = {
    commercial = var.wiz_commercial_client_secret
    govcloud   = var.wiz_govcloud_client_secret
  }
}

output "wiz_integration_ids" {
  value = module.wiz_integrations.ids
}
```

### Importing an Existing Integration

Existing integrations can be imported by ID (`in-<RANDOM STRING>`) into the module's resource address:

```shell
tofu import 'module.wiz_integration.scalr_wiz_integration.this["iac_scanning"]' in-xxxxxxxxxx
```

The client secret is never returned by the Scalr API, so the first plan after an import shows the secret as a pending in-place change until it is applied.

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
| scalr_wiz_integration.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_wiz_client_secrets"></a> [wiz\_client\_secrets](#input\_wiz\_client\_secrets) | Map of sensitive Wiz service-account client secrets for var.wiz\_integrations, keyed by the same<br/>logical key. Kept in a separate, wholly `sensitive = true` variable so that<br/>var.wiz\_integrations itself can remain non-sensitive (required, since it is the for\_each source<br/>for scalr\_wiz\_integration.this). Every key in var.wiz\_integrations must have a non-empty entry<br/>here (at most 512 characters), because the underlying provider requires a client secret for<br/>every integration. Entries without a matching integration are ignored and are not validated.<br/><br/>Example:<br/>  wiz\_client\_secrets = {<br/>    iac\_scanning = var.wiz\_client\_secret<br/>  } | `map(string)` | `{}` | no |
| <a name="input_wiz_integrations"></a> [wiz\_integrations](#input\_wiz\_integrations) | Map of Scalr Wiz integrations keyed by a caller-chosen logical name. Each entry manages one<br/>`scalr_wiz_integration` resource, which lets Scalr run `wizcli` IaC scans as part of a run.<br/>The sensitive Wiz service-account client secret for each entry is intentionally NOT part of<br/>this variable -- see var.wiz\_client\_secrets. Keeping it out of this map lets<br/>var.wiz\_integrations remain non-sensitive, which is required because it is this module's<br/>for\_each source (OpenTofu/Terraform disallow for\_each over a sensitive collection).<br/><br/>Fields:<br/>  - name:              (Required) Name of the Wiz integration. Must not be blank and must be at<br/>                        most 128 characters.<br/>  - client\_id:         (Required) Wiz service-account client ID. Must not be blank and must be<br/>                        at most 255 characters.<br/>  - default\_policies:  (Optional) Set of Wiz CI/CD policy names passed to `wizcli` as<br/>                        `--policies`, one set element per policy. Elements must not be blank.<br/>  - default\_scan\_name: (Optional) Default scan name passed to `wizcli` as `--name`. When unset,<br/>                        scans are named "{workspace}-{run}". Must not be blank and must be at<br/>                        most 255 characters.<br/>  - endpoint\_mode:     (Optional) Wiz tenant region: the commercial, GovCloud, or FedRAMP<br/>                        auth/API host. Valid values are "commercial", "govcloud", and<br/>                        "fedramp". Defaults to "commercial".<br/>  - autofail:          (Optional) Block the run when the Wiz scan fails or cannot run. When<br/>                        false, Wiz failures are reported in the following Scalr policy check<br/>                        and do not block the Wiz stage. Defaults to false.<br/>  - environments:      (Optional) Set of environment IDs (env-<RANDOM STRING>) the integration<br/>                        is linked to. Use ["*"] to allow it in all current and future<br/>                        environments; "*" must then be the only element. When unset, the<br/>                        integration is created without environment links and the provider<br/>                        does not manage them afterwards.<br/><br/>Example:<br/>  wiz\_integrations = {<br/>    iac\_scanning = {<br/>      name             = "wiz"<br/>      client\_id        = "svc-account-client-id"<br/>      default\_policies = ["Default IaC policy"]<br/>      endpoint\_mode    = "commercial"<br/>      autofail         = false<br/>      environments     = ["env-xxxxxxxxxx"]<br/>    }<br/>  } | <pre>map(object({<br/>    name              = string<br/>    client_id         = string<br/>    default_policies  = optional(set(string))<br/>    default_scan_name = optional(string)<br/>    endpoint_mode     = optional(string, "commercial")<br/>    autofail          = optional(bool, false)<br/>    environments      = optional(set(string))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Wiz integration IDs (in-<RANDOM STRING>) keyed by the same logical name used in var.wiz\_integrations. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **Secrets live in a separate sensitive map.** `wiz_integrations` stays non-sensitive so it can drive `for_each` (OpenTofu/Terraform refuse `for_each` over a sensitive collection). Each integration's client secret is looked up by the same key from the wholly sensitive `wiz_client_secrets` map, the same pattern as `modules/scalr/vcs_provider`. The `client_id` is not a secret and stays in the main map.
- **Every integration must have a client secret.** A cross-variable validation on `wiz_client_secrets` fails the plan, naming the missing keys, when an integration has no entry. Null, empty, whitespace-only, and longer-than-512-character secrets are rejected too, but only for configured integrations: surplus entries in `wiz_client_secrets` are ignored and are not validated. Cross-variable validation needs OpenTofu or Terraform `>= 1.9.0`.
- **No whole-object output.** Unlike some sibling modules, this module does not output the full `scalr_wiz_integration` objects because they carry the sensitive `client_secret`. It outputs only the explicit non-sensitive `ids` projection, keyed by the logical name. The resource has no other read-only attributes.
- **`endpoint_mode` is validated.** It must be `commercial`, `govcloud`, or `fedramp` (default `commercial`), matching the provider schema.
- **`environments` and the `"*"` wildcard.** Use `["*"]` to allow the integration in all current and future environments. The provider only recognizes `"*"` when it is the sole element, so the module rejects `"*"` mixed with explicit environment IDs. The provider treats `environments` as optional and computed: when it is omitted the integration is created without environment links and the provider does not manage them afterwards, so omit it only if the links are managed elsewhere.
- **`autofail` defaults to `false`.** When `false`, Wiz scan failures appear in the following Scalr policy check and do not block the Wiz stage. Set it to `true` to block the run when the scan fails or cannot run.
- **Provider-side limits.** `name` is limited to 128 characters, `client_id` and `default_scan_name` to 255, and `client_secret` to 512. Blank values are rejected. The module mirrors these so mistakes surface at plan time without contacting Scalr.
- **Connection failures are warnings, not errors.** If Scalr reports a failure for the integration, the provider still saves it and emits a warning rather than failing the apply.
- **Client secret rotation.** Changing a value in `wiz_client_secrets` updates the integration in place. The provider always sends the secret on update because the Scalr API never returns it, so drift in the secret itself cannot be detected.

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
