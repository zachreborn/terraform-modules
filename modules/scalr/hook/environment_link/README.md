<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Hook Environment Link Module</h3>
  <p align="center">
    This module manages <code>scalr_environment_hook</code> resources in Scalr, linking a <a href="..">hook</a> to an environment for one or more workflow events (pre-init, pre-plan, post-plan, pre-apply, post-apply).
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

- A `scalr_hook` must already exist; see the [`hook`](..) submodule. `hook_id` references it.
- The target Scalr environment must already exist; `environment_id` references it.

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

### Linking All Events

```hcl
module "hook_environment_link" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/hook/environment_link"

  environment_hooks = {
    notify_slack_all_events = {
      hook_id        = module.hook.ids["notify_slack"]
      environment_id = "env-xxxxxxxxxx"
      events         = ["*"]
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
| scalr_environment_hook.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment_hooks"></a> [environment\_hooks](#input\_environment\_hooks) | Map of Scalr environment hook links keyed by a caller-supplied logical name. Each entry<br/>manages one `scalr_environment_hook` resource, attaching a hook (see the sibling<br/>`hook` submodule) to a specific environment for one or more workflow events.<br/><br/>Fields:<br/>  - hook\_id:        (Required) ID of the hook, in the format "hook-<RANDOM STRING>".<br/>  - environment\_id: (Required) ID of the environment, in the format "env-<RANDOM STRING>".<br/>  - events:         (Required) Set of events that trigger the hook execution. Valid values<br/>                     are "pre-init", "pre-plan", "post-plan", "pre-apply", "post-apply", or<br/>                     the single-element set ["*"] to select all events.<br/><br/>Example:<br/>  environment\_hooks = {<br/>    notify\_prod = {<br/>      hook\_id        = module.hook.ids["notify"]<br/>      environment\_id = "env-xxxxxxxxxx"<br/>      events         = ["pre-apply", "post-apply"]<br/>    }<br/>  } | <pre>map(object({<br/>    hook_id        = string<br/>    environment_id = string<br/>    events         = set(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_environment_hooks"></a> [environment\_hooks](#output\_environment\_hooks) | Map of full scalr\_environment\_hook resource objects keyed by the same logical name used in var.environment\_hooks. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr environment hook link IDs keyed by the same logical name used in var.environment\_hooks. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **`events` validation.** Each entry's `events` set must be either the single-element set `["*"]` (all events) or a subset of `pre-init`, `pre-plan`, `post-plan`, `pre-apply`, `post-apply`, matching the provider's documented valid values.
- **Static map keys.** `hook_id` and `environment_id` are accepted as plain string values (which may themselves be apply-time-unknown references, e.g. `module.hook.ids["notify_slack"]`), while the `for_each` key is always the caller-supplied logical name — never derived from an ID — so the resource remains resolvable even before those IDs are known.

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
