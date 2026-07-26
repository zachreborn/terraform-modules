<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Agent Pool Token Module</h3>
  <p align="center">
    This module manages Scalr agent pool tokens (<code>scalr_agent_pool_token</code>).
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

- An existing Scalr agent pool (`agent_pool_id`), e.g. from the sibling `modules/scalr/agent_pool` module.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "agent_pool_tokens" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/agent_pool/token"

  agent_pool_tokens = {
    ci_runner = {
      agent_pool_id = "apool-xxxxxxxxxx"
      description   = "Token for the CI runner fleet"
    }
  }
}

# module.agent_pool_tokens.tokens["ci_runner"] is sensitive -- write it to a secret store, never to
# plain-text output.
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `tokens` is marked `sensitive = true` since it exposes the actual agent pool token secret. Treat it the same
  way you would any other generated credential -- write it directly to a secret manager rather than passing it
  through further non-sensitive outputs or logs.
- This is a standalone companion submodule to `modules/scalr/agent_pool`, following the single-resource-focus
  convention. It can be used directly (as shown above) or indirectly via that module's own `agent_pool_tokens`
  input, which resolves `agent_pool_id` from its own `scalr_agent_pool` resources -- see that module's README.

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
| scalr_agent_pool_token.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_agent_pool_tokens"></a> [agent\_pool\_tokens](#input\_agent\_pool\_tokens) | (Required) Map of Scalr agent pool tokens (`scalr_agent_pool_token`) to create, keyed by a caller-chosen<br/>logical name.<br/>Fields:<br/>  - agent\_pool\_id: (Required) ID of the agent pool, in the format `apool-<RANDOM STRING>`.<br/>  - description:   (Optional) Description of the token. | <pre>map(object({<br/>    agent_pool_id = string<br/>    description   = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr agent pool token resource IDs, keyed by the same keys as var.agent\_pool\_tokens. |
| <a name="output_tokens"></a> [tokens](#output\_tokens) | Map of the actual agent pool token secret values, keyed by the same keys as var.agent\_pool\_tokens. Sensitive. |
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
