<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Account Allowed IPs Module</h3>
  <p align="center">
    This module manages <code>scalr_account_allowed_ips</code> resources in Scalr, restricting which source IPs/CIDRs may access an account.
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

> [!WARNING]
> **Lockout risk.** If you apply this module without including your own current public IP address (or CIDR range) in `allowed_ips`, you and everyone else may be **immediately locked out of the Scalr account** — including out of the Scalr UI, API, and CLI. There is **no self-service recovery path**: restoring access requires the account owner to open a support ticket at [support.scalr.com](https://support.scalr.com) and wait for Scalr support to intervene. Before applying, double-check that `allowed_ips` includes every network your team, CI/CD runners, and this OpenTofu/Terraform run itself will connect from.

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

- Know every IP address and CIDR range that legitimately needs access to the account **before** applying, including your own current IP.

### Simple Example

```hcl
module "account_allowed_ips" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/account_allowed_ips"

  account_allowed_ips = {
    default = {
      account_id  = "acc-xxxxxxxxxx"
      allowed_ips = [var.caller_ip_address, "<office-network-cidr>", "<ci-runner-cidr>"]
    }
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.17.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_account_allowed_ips.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_allowed_ips"></a> [account\_allowed\_ips](#input\_account\_allowed\_ips) | Map of Scalr account allowed-IP lists keyed by a caller-supplied logical name. Each entry<br/>manages one `scalr_account_allowed_ips` resource, restricting which source IPs/CIDRs may<br/>access the account.<br/><br/>WARNING: if you omit your own current IP address (or CIDR range) from `allowed_ips`, you<br/>may immediately lock yourself (and everyone else) out of the account. Recovering from a<br/>lockout requires the account owner to open a Scalr support ticket<br/>(https://support.scalr.com) — there is no self-service recovery path. See the README's<br/>"Notes / Design Decisions" section before using this module.<br/><br/>Fields:<br/>  - account\_id:  (Optional) ID of the account, in the format "acc-<RANDOM STRING>". Falls<br/>                 back to var.account\_id when unset.<br/>  - allowed\_ips: (Required) Non-empty list of allowed IPs or CIDRs.<br/><br/>Example:<br/>  account\_allowed\_ips = {<br/>    default = {<br/>      account\_id  = "acc-xxxxxxxxxx"<br/>      allowed\_ips = [var.caller\_ip\_address, "<office-network-cidr>"]<br/>    }<br/>  } | <pre>map(object({<br/>    account_id  = optional(string)<br/>    allowed_ips = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | (Optional) Default Scalr account ID, in the format "acc-<RANDOM STRING>", used for any account\_allowed\_ips entry that does not set its own account\_id. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_allowed_ips"></a> [account\_allowed\_ips](#output\_account\_allowed\_ips) | Map of full scalr\_account\_allowed\_ips resource objects keyed by the same logical name used in var.account\_allowed\_ips. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr account allowed-IP resource IDs (equal to the account ID) keyed by the same logical name used in var.account\_allowed\_ips. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **Lockout warning (see above).** This is the single most important thing to understand before using this module. Test changes in a non-production account first if possible, and keep a support contact on hand in case of an unexpected lockout.
- **Recovery path.** There is no Terraform/OpenTofu-side or self-service recovery from a lockout. The account owner must open a ticket at [support.scalr.com](https://support.scalr.com); Scalr support restores access manually.
- **Non-empty list required.** A validation rule rejects an empty `allowed_ips` list per entry, since an empty list is almost never intentional and is a common source of accidental lockouts.
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
