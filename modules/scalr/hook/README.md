<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Hook Module</h3>
  <p align="center">
    This module manages <code>scalr_hook</code> resources in Scalr. Hooks are custom scripts that can be executed at different stages of the OpenTofu/Terraform workflow (pre-init, pre-plan, post-plan, pre-apply, post-apply). Pair this module with <a href="./environment_link">hook/environment_link</a> to attach a hook to one or more environments.
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

- A Scalr VCS provider (`scalr_vcs_provider` or the `modules/scalr` root's `vcs_provider_config`) must already exist; `vcs_provider_id` references it.
- The VCS repository referenced by `vcs_repo.identifier` must contain the script at `scriptfile_path`.

### Simple Example

```hcl
module "hook" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/hook"

  hooks = {
    notify_slack = {
      name            = "notify-slack"
      interpreter     = "bash"
      scriptfile_path = "hooks/notify.sh"
      vcs_provider_id = "vcs-xxxxxxxxxx"
      description     = "Posts a Slack message before every apply."
      vcs_repo = {
        identifier = "my-org/my-hooks-repo"
        branch     = "main"
      }
    }
  }
}
```

### Linking a Hook to an Environment

```hcl
module "hook" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/hook"

  hooks = {
    notify_slack = {
      name            = "notify-slack"
      interpreter     = "bash"
      scriptfile_path = "hooks/notify.sh"
      vcs_provider_id = "vcs-xxxxxxxxxx"
      vcs_repo = {
        identifier = "my-org/my-hooks-repo"
      }
    }
  }
}

module "hook_environment_link" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/hook/environment_link"

  environment_hooks = {
    notify_slack_prod = {
      hook_id        = module.hook.ids["notify_slack"]
      environment_id = "env-xxxxxxxxxx"
      events         = ["pre-apply", "post-apply"]
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
| scalr_hook.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_hooks"></a> [hooks](#input\_hooks) | Map of Scalr hooks keyed by a caller-supplied logical name. Each entry manages one<br/>`scalr_hook` resource, which allows custom scripts to run at different stages of the<br/>OpenTofu/Terraform workflow once linked to an environment via the companion<br/>`hook/environment_link` submodule.<br/><br/>Fields:<br/>  - name:            (Required) Name of the hook.<br/>  - interpreter:      (Required) The interpreter to execute the hook script, e.g. "bash", "python3".<br/>  - scriptfile\_path:  (Required) Path to the script file in the VCS repository.<br/>  - vcs\_provider\_id:  (Required) ID of the VCS provider, in the format "vcs-<RANDOM STRING>".<br/>  - description:      (Optional) Description of the hook.<br/>  - vcs\_repo:          (Required) Source configuration of the VCS repository. Although the<br/>                       published provider docs list this block as optional, the released<br/>                       provider (>= 3.17.0) enforces it as required via a schema validator;<br/>                       omitting it fails with "Block vcs\_repo must have a configuration value<br/>                       as the provider has marked it as required".<br/>      - identifier: (Required) The identifier of the VCS repository, in the format ":org/:repo".<br/>      - branch:     (Optional) Repository branch name.<br/><br/>Example:<br/>  hooks = {<br/>    pre\_apply\_notify = {<br/>      name            = "pre-apply-notify"<br/>      interpreter     = "bash"<br/>      scriptfile\_path = "hooks/notify.sh"<br/>      vcs\_provider\_id = "vcs-xxxxxxxxxx"<br/>      vcs\_repo = {<br/>        identifier = "my-org/my-hooks-repo"<br/>        branch     = "main"<br/>      }<br/>    }<br/>  } | <pre>map(object({<br/>    name            = string<br/>    interpreter     = string<br/>    scriptfile_path = string<br/>    vcs_provider_id = string<br/>    description     = optional(string)<br/>    vcs_repo = object({<br/>      identifier = string<br/>      branch     = optional(string)<br/>    })<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_hooks"></a> [hooks](#output\_hooks) | Map of full scalr\_hook resource objects keyed by the same logical name used in var.hooks. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr hook IDs keyed by the same logical name used in var.hooks. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **Single-resource focus.** This module manages only `scalr_hook`. Linking a hook to an environment (`scalr_environment_hook`) is handled by the companion [`hook/environment_link`](./environment_link) submodule, so a hook can be defined once and linked to many environments independently.
- **`vcs_repo` is a required, single block.** The provider's published docs list `vcs_repo` as optional, but the released provider (>= 3.17.0) enforces it as required via a schema validator ("Block vcs_repo must have a configuration value as the provider has marked it as required", confirmed via `tofu providers schema -json` and a live plan). This module models it as a required `object({...})` to match verified runtime behavior rather than the docs, and exposes it as a single object (not a list) for a simpler caller experience.

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
