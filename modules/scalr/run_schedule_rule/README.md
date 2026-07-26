<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Run Schedule Rule Module</h3>
  <p align="center">
    This module manages <code>scalr_run_schedule_rule</code> resources in Scalr, scheduling a recurring apply, destroy, or refresh run for a workspace.
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

- The workspace referenced by `workspace_id` must already exist.

### Simple Example

```hcl
module "run_schedule_rule" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/run_schedule_rule"

  run_schedule_rules = {
    nightly_apply = {
      schedule      = "0 4 * * *"
      schedule_mode = "apply"
      workspace_id  = "ws-xxxxxxxxxx"
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
| scalr_run_schedule_rule.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_run_schedule_rules"></a> [run\_schedule\_rules](#input\_run\_schedule\_rules) | Map of Scalr run schedule rules keyed by a caller-supplied logical name. Each entry manages<br/>one `scalr_run_schedule_rule` resource, scheduling a recurring apply, destroy, or refresh<br/>run for a workspace.<br/><br/>Fields:<br/>  - schedule:      (Required) Cron expression (5 fields, UTC) for the scheduled run.<br/>  - schedule\_mode: (Required) Mode of the scheduled run. Valid values are "apply",<br/>                    "destroy", and "refresh".<br/>  - workspace\_id:  (Required) ID of the workspace, in the format "ws-<RANDOM STRING>".<br/><br/>Example:<br/>  run\_schedule\_rules = {<br/>    nightly\_apply = {<br/>      schedule      = "0 4 * * *"<br/>      schedule\_mode = "apply"<br/>      workspace\_id  = "ws-xxxxxxxxxx"<br/>    }<br/>  } | <pre>map(object({<br/>    schedule      = string<br/>    schedule_mode = string<br/>    workspace_id  = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr run schedule rule IDs keyed by the same logical name used in var.run\_schedule\_rules. |
| <a name="output_run_schedule_rules"></a> [run\_schedule\_rules](#output\_run\_schedule\_rules) | Map of full scalr\_run\_schedule\_rule resource objects keyed by the same logical name used in var.run\_schedule\_rules. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **Relationship to `workspace_run_schedule`.** `scalr_run_schedule_rule` is a more granular, per-rule alternative to `scalr_workspace_run_schedule` (see the sibling [`workspace_run_schedule`](../workspace_run_schedule) module), supporting a `refresh` mode in addition to `apply`/`destroy` and allowing multiple independent rules per workspace.
- **Cron shape check only.** The `schedule` validation only confirms a 5-field, whitespace-separated shape; semantic range checking is left to the provider, which validates server-side.

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
