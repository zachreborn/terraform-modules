<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Slack Integration Module</h3>
  <p align="center">
    This module manages <code>scalr_slack_integration</code> resources in Scalr, sending Slack notifications when configured run events occur.
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

- The Slack workspace must already be connected to the Scalr account before using this module.

### Simple Example

```hcl
module "slack_integration" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/integrations/slack"

  slack_integrations = {
    run_notifications = {
      name         = "my-channel"
      channel_id   = "C0000000000"
      events       = ["run_approval_required", "run_success", "run_errored", "drift_detected"]
      environments = ["env-xxxxxxxxxx"]
      run_mode     = "apply"
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
| scalr_slack_integration.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | (Optional) Default Scalr account ID, in the format "acc-<RANDOM STRING>", used for any slack\_integrations entry that does not set its own account\_id. | `string` | `null` | no |
| <a name="input_slack_integrations"></a> [slack\_integrations](#input\_slack\_integrations) | Map of Scalr Slack integrations keyed by a caller-supplied logical name. Each entry<br/>manages one `scalr_slack_integration` resource, sending a Slack notification to a channel<br/>when configured run events occur. The Slack workspace must already be connected to the<br/>Scalr account before using this resource.<br/><br/>Fields:<br/>  - name:         (Required) Name of the Slack integration.<br/>  - channel\_id:   (Required) Slack channel ID the event will be sent to (found in the<br/>                   Slack UI's channel settings/info popup).<br/>  - events:       (Required) Set of run events to notify on. Valid values are<br/>                   "run\_approval\_required", "run\_success", "run\_errored", and<br/>                   "drift\_detected".<br/>  - environments: (Required) List of environments where events should be triggered.<br/>  - workspaces:   (Optional) List of workspaces where events should be triggered. Must be<br/>                   within the given environments; if omitted for an environment, events<br/>                   trigger for all of its workspaces.<br/>  - run\_mode:     (Optional) What type of runs should be reported. Valid values are "all",<br/>                   "apply", and "dry".<br/>  - account\_id:   (Optional) ID of the account, in the format "acc-<RANDOM STRING>". Falls<br/>                   back to var.account\_id when unset.<br/><br/>Example:<br/>  slack\_integrations = {<br/>    run\_notifications = {<br/>      name         = "my-channel"<br/>      channel\_id   = "C0000000000"<br/>      events       = ["run\_approval\_required", "run\_errored"]<br/>      environments = ["env-xxxxxxxxxx"]<br/>    }<br/>  } | <pre>map(object({<br/>    name         = string<br/>    channel_id   = string<br/>    events       = set(string)<br/>    environments = set(string)<br/>    workspaces   = optional(set(string))<br/>    run_mode     = optional(string)<br/>    account_id   = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Slack integration IDs keyed by the same logical name used in var.slack\_integrations. |
| <a name="output_slack_integrations"></a> [slack\_integrations](#output\_slack\_integrations) | Map of full scalr\_slack\_integration resource objects keyed by the same logical name used in var.slack\_integrations. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **`events` enum validation.** Each entry's `events` set is validated against the provider's documented enum (`run_approval_required`, `run_success`, `run_errored`, `drift_detected`).
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
