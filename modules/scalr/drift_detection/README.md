<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Drift Detection Module</h3>
  <p align="center">
    This module manages <code>scalr_drift_detection</code> resources in Scalr, periodically checking workspaces in an environment for infrastructure drift.
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

- The environment referenced by `environment_id` must already exist.

### Simple Example

```hcl
module "drift_detection" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/drift_detection"

  drift_detections = {
    prod_weekly = {
      environment_id = "env-xxxxxxxxxx"
      check_period   = "weekly"
    }
  }
}
```

### With a Workspace Filter

```hcl
module "drift_detection" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/drift_detection"

  drift_detections = {
    prod_weekly = {
      environment_id = "env-xxxxxxxxxx"
      check_period   = "weekly"
      run_mode       = "plan"
      workspace_filters = {
        name_patterns = ["prod", "stage-*"]
      }
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
| scalr_drift_detection.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_drift_detections"></a> [drift\_detections](#input\_drift\_detections) | Map of Scalr drift detection schedulers keyed by a caller-supplied logical name. Each entry<br/>manages one `scalr_drift_detection` resource, periodically checking one or more workspaces<br/>in an environment for infrastructure drift.<br/><br/>Fields:<br/>  - environment\_id: (Required) ID of the environment, in the format "env-<RANDOM STRING>".<br/>  - check\_period:   (Required) Check period for drift detection. Valid values are "daily"<br/>                     and "weekly".<br/>  - run\_mode:       (Optional, default "refresh-only") Run mode for drift detection. Valid<br/>                     values are "refresh-only" and "plan".<br/>  - workspace\_filters: (Optional) Filters for which workspaces are included in drift<br/>                     detection. At most one of name\_patterns, environment\_types, or tags may<br/>                     be set per entry.<br/>      - name\_patterns:     (Optional) Workspace name patterns to include. Supports the "*"<br/>                            wildcard (e.g. "prod-*").<br/>      - environment\_types: (Optional) Workspace environment types to include. Valid values<br/>                            are "production", "staging", "testing", "development", and<br/>                            "unmapped".<br/>      - tags:              (Optional) Workspace tags to include. A workspace matches if it<br/>                            has at least one of the specified tags.<br/><br/>Example:<br/>  drift\_detections = {<br/>    prod\_weekly = {<br/>      environment\_id = "env-xxxxxxxxxx"<br/>      check\_period   = "weekly"<br/>      run\_mode       = "plan"<br/>      workspace\_filters = {<br/>        name\_patterns = ["prod", "stage-*"]<br/>      }<br/>    }<br/>  } | <pre>map(object({<br/>    environment_id = string<br/>    check_period   = string<br/>    run_mode       = optional(string, "refresh-only")<br/>    workspace_filters = optional(object({<br/>      name_patterns     = optional(set(string))<br/>      environment_types = optional(set(string))<br/>      tags              = optional(set(string))<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_drift_detections"></a> [drift\_detections](#output\_drift\_detections) | Map of full scalr\_drift\_detection resource objects keyed by the same logical name used in var.drift\_detections. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr drift detection scheduler IDs keyed by the same logical name used in var.drift\_detections. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **At most one workspace filter type.** The provider only supports a single filter dimension per `workspace_filters` block; a validation rule rejects any entry that sets more than one of `name_patterns`, `environment_types`, or `tags`.
- **Enum validation.** `check_period` and `run_mode` are validated against the provider's documented enums; `workspace_filters.environment_types` entries are validated against Scalr's workspace environment type enum.

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
