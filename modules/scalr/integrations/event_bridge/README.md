<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr EventBridge Integration Module</h3>
  <p align="center">
    This module manages <code>scalr_event_bridge_integration</code> resources in Scalr, creating an Amazon EventBridge event source that Scalr can publish run events to.
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

- The target AWS account and region where the EventBridge partner event source will be accepted.

### Simple Example

```hcl
module "event_bridge_integration" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/integrations/event_bridge"

  event_bridge_integrations = {
    default = {
      name           = "via-provider-aws-bridge"
      aws_account_id = "111267354555"
      region         = "us-east-1"
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
| scalr_event_bridge_integration.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_event_bridge_integrations"></a> [event\_bridge\_integrations](#input\_event\_bridge\_integrations) | Map of Scalr EventBridge integrations keyed by a caller-supplied logical name. Each entry<br/>manages one `scalr_event_bridge_integration` resource, creating an Amazon EventBridge event<br/>source that Scalr can publish run events to.<br/><br/>Fields:<br/>  - name:           (Required) Name of the EventBridge integration.<br/>  - aws\_account\_id: (Required) AWS account ID, in the format of a 12-digit account number.<br/>  - region:         (Required) AWS region, e.g. "us-east-1".<br/><br/>After creation, the caller must accept the resulting event source (exposed via the<br/>`event_source_name`/`event_source_arn` outputs) as an EventBridge partner event source in<br/>the target AWS account/region — this module only manages the Scalr side of the pairing.<br/><br/>Example:<br/>  event\_bridge\_integrations = {<br/>    default = {<br/>      name           = "via-provider-aws-bridge"<br/>      aws\_account\_id = "111267354555"<br/>      region         = "us-east-1"<br/>    }<br/>  } | <pre>map(object({<br/>    name           = string<br/>    aws_account_id = string<br/>    region         = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_event_bridge_integrations"></a> [event\_bridge\_integrations](#output\_event\_bridge\_integrations) | Map of full scalr\_event\_bridge\_integration resource objects keyed by the same logical name used in var.event\_bridge\_integrations. |
| <a name="output_event_source_arns"></a> [event\_source\_arns](#output\_event\_source\_arns) | Map of the EventBridge event source ARNs keyed by the same logical name used in var.event\_bridge\_integrations. Accept this event source as an EventBridge partner event source in the target AWS account/region. |
| <a name="output_event_source_names"></a> [event\_source\_names](#output\_event\_source\_names) | Map of the EventBridge event source names keyed by the same logical name used in var.event\_bridge\_integrations. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr EventBridge integration IDs keyed by the same logical name used in var.event\_bridge\_integrations. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **`aws_account_id` format guard.** A validation rule enforces the 12-digit AWS account ID format at plan time.
- **Two-sided pairing.** This module only manages the Scalr side of the integration. The AWS account owner must separately accept the resulting event source (`event_source_name`/`event_source_arn` outputs) as an EventBridge partner event source in the AWS console or via an `aws_cloudwatch_event_bus`/partner-source resource in that AWS account.

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
