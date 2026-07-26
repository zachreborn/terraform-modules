<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Variable Module</h3>
  <p align="center">
    This module manages one or more Scalr variables (<code>scalr_variable</code>), scoped to an account,
    environment, workspace, or variable set.
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
    <li><a href="#prerequisites">Prerequisites</a></li>
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

## Prerequisites

- A Scalr account and a configured `scalr` provider.
- The scope target for each entry: an `account_id`, `environment_id` (e.g. from `modules/scalr` root module or the
  `scalr_environment` resource), `workspace_id` (e.g. from the `scalr_workspace` resource), or `var_set_id` (e.g.
  from `modules/scalr/var_set`) that the variable should belong to.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "variables" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/variable"

  variables = {
    aws_region = {
      key          = "AWS_REGION"
      category     = "shell"
      workspace_id = "ws-xxxxxxxxxx"
    }
    db_password = {
      key          = "db_password"
      category     = "terraform"
      sensitive    = true
      workspace_id = "ws-xxxxxxxxxx"
    }
  }

  values = {
    aws_region  = "us-east-1"
    db_password = "correct-horse-battery-staple"
  }
}
```

### Write-only value example (Terraform/OpenTofu 1.11+)

```hcl
module "variables" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/variable"

  variables = {
    api_token = {
      key              = "api_token"
      category         = "terraform"
      sensitive        = true
      value_wo_version = 1
      workspace_id     = "ws-xxxxxxxxxx"
    }
  }

  values_wo = {
    api_token = var.ephemeral_api_token
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **Why `value`/`value_wo` are separate variables, not attributes of `var.variables`:** OpenTofu/Terraform can only
  mark an entire variable as `sensitive`, not a single attribute inside an object-typed variable. Nesting `value`
  inside `var.variables` would force the whole entry (key, category, scope IDs, etc.) to be hidden from plan output
  to keep the value safe, or leave the value un-redacted if the whole variable were left non-sensitive. Splitting
  the value out into always-sensitive `var.values` / `var.values_wo` maps (keyed by the same logical name) keeps
  every other field visible for review while guaranteeing the actual value is never shown in plan/apply output.
- `category` defaults to `"terraform"` when unset, matching the provider's own default.
- Exactly one of `account_id`, `environment_id`, `workspace_id`, or `var_set_id` must be set per entry; this is
  enforced by a `validation` block.
- `value_wo`/`value_wo_version` require Terraform or OpenTofu 1.11 or later. Set `values_wo` (with a matching
  `value_wo_version` bump on the corresponding `var.variables` entry) to avoid ever persisting a value to state,
  e.g. when sourcing from an ephemeral resource or write-only data source.

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
| scalr_variable.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_values"></a> [values](#input\_values) | (Optional) Map of variable values (the `value` attribute of `scalr_variable`), keyed by the same keys as<br/>var.variables. Kept as a separate, always-sensitive variable rather than an attribute nested inside<br/>var.variables, since OpenTofu/Terraform cannot mark a single attribute of an object-typed variable as<br/>sensitive -- only whole variables can be marked sensitive. Splitting the value out keeps the rest of each<br/>entry's metadata (key, category, scope, etc.) visible in plan output while still guaranteeing the actual<br/>value is never displayed.<br/>An entry may be omitted here if the corresponding var.variables entry sets a value via var.values\_wo instead. | `map(string)` | `{}` | no |
| <a name="input_values_wo"></a> [values\_wo](#input\_values\_wo) | (Optional) Map of write-only variable values (the `value_wo` attribute of `scalr_variable`, supported on<br/>Terraform/OpenTofu 1.11+), keyed by the same keys as var.variables. Use this instead of var.values when the<br/>source value is itself ephemeral (e.g. sourced from an ephemeral resource or write-only data source) and<br/>must never be persisted to state. The corresponding var.variables entry's value\_wo\_version must be<br/>incremented whenever the value here changes, since OpenTofu/Terraform has no other way to detect that a<br/>write-only value changed. | `map(string)` | `{}` | no |
| <a name="input_variables"></a> [variables](#input\_variables) | (Required) Map of Scalr variables (`scalr_variable`) to create, keyed by a caller-chosen logical name.<br/>This variable intentionally excludes the variable's actual value -- see var.values / var.values\_wo below.<br/>Fields:<br/>  - key:              (Required) Key of the variable.<br/>  - category:         (Optional) Either "terraform" or "shell". Defaults to "terraform".<br/>  - hcl:               (Optional) Whether the value is a string of HCL code. Has no effect for shell<br/>                       variables. Defaults to false.<br/>  - sensitive:        (Optional) Whether the value is sensitive (masked after being set). Defaults to false.<br/>  - final:            (Optional) Whether the variable can be overridden on a lower scope. Defaults to false.<br/>  - force:            (Optional) Whether to force-create a final variable even if the same variable<br/>                       already exists on a lower scope (which is then deleted). Defaults to false.<br/>  - description:      (Optional) Verbose description of the variable.<br/>  - account\_id:       (Optional) ID of the account that owns the variable, in the format `acc-<RANDOM STRING>`.<br/>  - environment\_id:   (Optional) ID of the environment that owns the variable, in the format `env-<RANDOM STRING>`.<br/>  - workspace\_id:     (Optional) ID of the workspace that owns the variable, in the format `ws-<RANDOM STRING>`.<br/>  - var\_set\_id:       (Optional) ID of the variable set this variable belongs to, in the format<br/>                       `varset-<RANDOM STRING>`.<br/>  - value\_wo\_version: (Optional) Version number for the corresponding var.values\_wo entry. Increment this<br/>                       number to apply an updated write-only value. Only relevant when a var.values\_wo entry<br/>                       is set for this key.<br/>Exactly one of account\_id, environment\_id, workspace\_id, or var\_set\_id must be set per entry -- this defines<br/>the scope the variable is created in. | <pre>map(object({<br/>    key              = string<br/>    category         = optional(string, "terraform")<br/>    hcl              = optional(bool, false)<br/>    sensitive        = optional(bool, false)<br/>    final            = optional(bool, false)<br/>    force            = optional(bool, false)<br/>    description      = optional(string)<br/>    account_id       = optional(string)<br/>    environment_id   = optional(string)<br/>    workspace_id     = optional(string)<br/>    var_set_id       = optional(string)<br/>    value_wo_version = optional(number)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr variable IDs, keyed by the same keys as var.variables. |
| <a name="output_readable_values"></a> [readable\_values](#output\_readable\_values) | Map of the non-sensitive read-only copy of each variable's value, keyed by the same keys as var.variables. Per the Scalr provider, this is null for any entry where sensitive = true. |
| <a name="output_updated_at"></a> [updated\_at](#output\_updated\_at) | Map of the last-updated timestamps, keyed by the same keys as var.variables. |
| <a name="output_updated_by_email"></a> [updated\_by\_email](#output\_updated\_by\_email) | Map of the email address of the user who last updated each variable, keyed by the same keys as var.variables. |
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

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasaurus)
- [Brad Engberg](https://github.com/bradms98)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->

[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
