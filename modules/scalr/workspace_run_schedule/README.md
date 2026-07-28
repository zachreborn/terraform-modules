<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Workspace Run Schedule Module</h3>
  <p align="center">
    This module manages <code>scalr_workspace_run_schedule</code> resources in Scalr, automating recurring apply and/or destroy runs for a workspace.
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
module "workspace_run_schedule" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/workspace_run_schedule"

  workspace_run_schedules = {
    nightly_refresh = {
      workspace_id     = "ws-xxxxxxxxxx"
      apply_schedule   = "30 3 5 3-5 2"
      destroy_schedule = "30 4 5 3-5 2"
    }
  }
}
```

### Apply-Only Schedule

```hcl
module "workspace_run_schedule" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/workspace_run_schedule"

  workspace_run_schedules = {
    weekday_morning_plan = {
      workspace_id   = "ws-xxxxxxxxxx"
      apply_schedule = "0 8 * * 1-5"
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
| scalr_workspace_run_schedule.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_workspace_run_schedules"></a> [workspace\_run\_schedules](#input\_workspace\_run\_schedules) | Map of Scalr workspace run schedules keyed by a caller-supplied logical name. Each entry<br/>manages one `scalr_workspace_run_schedule` resource, automating recurring apply and/or<br/>destroy runs for a workspace.<br/><br/>Fields:<br/>  - workspace\_id:     (Required) ID of the workspace, in the format "ws-<RANDOM STRING>".<br/>  - apply\_schedule:   (Optional) Cron expression (5 fields, UTC) for when an apply run<br/>                       should be created.<br/>  - destroy\_schedule: (Optional) Cron expression (5 fields, UTC) for when a destroy run<br/>                       should be created.<br/><br/>At least one of apply\_schedule or destroy\_schedule must be set.<br/><br/>Example:<br/>  workspace\_run\_schedules = {<br/>    nightly\_refresh = {<br/>      workspace\_id   = "ws-xxxxxxxxxx"<br/>      apply\_schedule = "30 3 5 3-5 2"<br/>    }<br/>  } | <pre>map(object({<br/>    workspace_id     = string<br/>    apply_schedule   = optional(string)<br/>    destroy_schedule = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr workspace run schedule IDs (equal to the workspace ID) keyed by the same logical name used in var.workspace\_run\_schedules. |
| <a name="output_workspace_run_schedules"></a> [workspace\_run\_schedules](#output\_workspace\_run\_schedules) | Map of full scalr\_workspace\_run\_schedule resource objects keyed by the same logical name used in var.workspace\_run\_schedules. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **At least one schedule required.** A validation rule rejects any entry that sets neither `apply_schedule` nor `destroy_schedule`, since such an entry would create a resource that does nothing.
- **Cron shape check only.** The `apply_schedule`/`destroy_schedule` validations only confirm a 5-field, whitespace-separated shape; semantic range checking (e.g. valid minute/hour bounds) is left to the provider, which validates server-side.
- **Resource ID equals workspace ID.** Per the provider docs, the resource's `id` equals the workspace's ID; there is exactly one schedule per workspace.

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
