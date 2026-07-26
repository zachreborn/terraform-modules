<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Run Trigger Module</h3>
  <p align="center">
    This module manages <code>scalr_run_trigger</code> resources in Scalr, chaining workspaces together so a successful run in an upstream workspace automatically starts a run in a downstream workspace.
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

- Both the upstream and downstream workspaces referenced must already exist.

### Simple Example

```hcl
data "scalr_workspace" "downstream" {
  name           = "downstream"
  environment_id = "env-xxxxxxxxxx"
}

data "scalr_workspace" "upstream" {
  name           = "upstream"
  environment_id = "env-xxxxxxxxxx"
}

module "run_trigger" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/run_trigger"

  run_triggers = {
    promote_to_downstream = {
      downstream_id = data.scalr_workspace.downstream.id
      upstream_id   = data.scalr_workspace.upstream.id
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
| scalr_run_trigger.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_run_triggers"></a> [run\_triggers](#input\_run\_triggers) | Map of Scalr run triggers keyed by a caller-supplied logical name. Each entry manages one<br/>`scalr_run_trigger` resource, chaining an upstream workspace's successful run into an<br/>automatic run in a downstream workspace.<br/><br/>Fields:<br/>  - downstream\_id: (Required) ID of the workspace in which new runs will be triggered.<br/>  - upstream\_id:   (Required) ID of the upstream workspace.<br/><br/>Example:<br/>  run\_triggers = {<br/>    promote\_to\_staging = {<br/>      downstream\_id = "ws-downstream0"<br/>      upstream\_id   = "ws-upstream000"<br/>    }<br/>  } | <pre>map(object({<br/>    downstream_id = string<br/>    upstream_id   = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr run trigger IDs keyed by the same logical name used in var.run\_triggers. |
| <a name="output_run_triggers"></a> [run\_triggers](#output\_run\_triggers) | Map of full scalr\_run\_trigger resource objects keyed by the same logical name used in var.run\_triggers. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **Self-trigger guard.** A validation rule rejects any entry where `downstream_id` and `upstream_id` are the same literal value, since a workspace cannot meaningfully trigger itself. This only catches literal self-references known at plan time; it does not (and cannot) prevent longer trigger cycles across multiple entries.

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
