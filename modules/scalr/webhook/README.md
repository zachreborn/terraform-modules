<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Webhook Module</h3>
  <p align="center">
    This module manages <code>scalr_webhook</code> resources in Scalr, posting a payload to an external endpoint whenever configured run events occur.
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

- The environment(s) referenced in `environments` must already exist.

### Simple Example

```hcl
module "webhook" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/webhook"

  webhooks = {
    run_notifications = {
      name         = "run-notifications"
      url          = "https://my-endpoint.example.com"
      events       = ["run:completed", "run:errored"]
      environments = ["env-xxxxxxxxxx"]
    }
  }
}
```

### With a Signing Secret and Custom Headers

```hcl
module "webhook" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/webhook"

  webhooks = {
    run_notifications = {
      name         = "run-notifications"
      url          = "https://my-endpoint.example.com"
      events       = ["run:completed", "run:errored"]
      environments = ["env-xxxxxxxxxx"]
      timeout      = 15
      max_attempts = 3
      header = [
        { name = "X-Source", value = "scalr" }
      ]
    }
  }

  # Keyed to match var.webhooks; kept out of the main object so it can be
  # sourced from a secret manager without tainting the rest of the config.
  webhook_secret_keys = {
    run_notifications = var.webhook_signing_secret
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.17.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | 3.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_webhook.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | (Optional) Default Scalr account ID, in the format "acc-<RANDOM STRING>", used for any webhooks entry that does not set its own account\_id. | `string` | `null` | no |
| <a name="input_webhook_secret_keys"></a> [webhook\_secret\_keys](#input\_webhook\_secret\_keys) | Map of secret\_key values used to sign each webhook's payload, keyed to match the same logical name used in var.webhooks. Sensitive. | `map(string)` | `{}` | no |
| <a name="input_webhooks"></a> [webhooks](#input\_webhooks) | Map of Scalr webhooks keyed by a caller-supplied logical name. Each entry manages one<br/>`scalr_webhook` resource, which posts a payload to an external endpoint when one or more<br/>Scalr run events occur.<br/><br/>Note: `secret_key` is intentionally NOT a field of this object. Supply it via the sibling<br/>`webhook_secret_keys` variable, keyed to the same logical name, so this variable (and any<br/>output derived from it) never needs to be marked sensitive.<br/><br/>Fields:<br/>  - name:         (Required) Name of the webhook.<br/>  - url:          (Required) Endpoint URL.<br/>  - events:       (Required) Set of event IDs, e.g. ["run:completed", "run:errored"].<br/>  - account\_id:   (Optional) ID of the account, in the format "acc-<RANDOM STRING>". Falls<br/>                   back to var.account\_id when unset.<br/>  - enabled:      (Optional, default true) Whether the webhook is enabled.<br/>  - environments: (Optional) Set of environment identifiers the webhook is shared to. Use<br/>                   ["*"] to share with all environments.<br/>  - header:       (Optional) Set of additional headers to send, each with `name` and `value`.<br/>  - max\_attempts: (Optional) Max delivery attempts of the payload.<br/>  - timeout:      (Optional) Endpoint timeout, in seconds.<br/><br/>Example:<br/>  webhooks = {<br/>    run\_notifications = {<br/>      name         = "run-notifications"<br/>      url          = "https://my-endpoint.example.com"<br/>      events       = ["run:completed", "run:errored"]<br/>      environments = ["env-xxxxxxxxxx"]<br/>      header = [<br/>        { name = "X-Source", value = "scalr" }<br/>      ]<br/>    }<br/>  } | <pre>map(object({<br/>    name         = string<br/>    url          = string<br/>    events       = set(string)<br/>    account_id   = optional(string)<br/>    enabled      = optional(bool, true)<br/>    environments = optional(set(string))<br/>    header = optional(set(object({<br/>      name  = string<br/>      value = string<br/>    })), [])<br/>    max_attempts = optional(number)<br/>    timeout      = optional(number)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr webhook IDs keyed by the same logical name used in var.webhooks. |
| <a name="output_webhooks"></a> [webhooks](#output\_webhooks) | Map of scalr\_webhook resource objects (excluding the write-only, provider-sensitive secret\_key attribute) keyed by the same logical name used in var.webhooks. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **`secret_key` lives in a separate, sensitive variable.** The provider marks `secret_key` as a sensitive attribute. Rather than marking the entire `webhooks` map(object) sensitive (which would taint every other field, including non-sensitive ones like `name` and `url`, in plan output), this module accepts secrets through the dedicated `webhook_secret_keys = map(string)` variable, keyed to the same logical name as `webhooks`. This keeps plan diffs readable for non-sensitive fields while still protecting the secret.
- **`webhooks` output omits `secret_key`.** Since `secret_key` is never read back, the `webhooks` output only surfaces the non-sensitive attributes.
- **`account_id` fallback.** Each entry may set its own `account_id`; entries that omit it fall back to the module-level `var.account_id`.

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
