<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Workspace Remote State Consumer Module</h3>
  <p align="center">
    This module lets Scalr workspaces read the state of other workspaces (<code>scalr_workspace_remote_state_consumer</code>).
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
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#usage">Usage</a></li>
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

- Scalr provider `>= 3.20.0`. The `scalr_workspace_remote_state_consumer` resource does not exist in earlier releases.
- Both workspaces must already exist (`workspace_id` is the source workspace whose state is shared, `consumer_id` is the workspace that is allowed to read it), e.g. from the sibling `modules/scalr/workspace` module, the root `modules/scalr` module, or the `scalr_workspace` resource.
- **The source workspace must have `remote_state_sharing = false`.** When sharing is enabled, the state is already readable by every workspace in the environment and there is no per-consumer list to manage. Set it on the source workspace explicitly (the provider otherwise falls back to the account-wide workspace state sharing setting). The sibling `modules/scalr/workspace` module accepts `remote_state_sharing` for this purpose.
- **Do not combine this module with the workspace's deprecated `remote_state_consumers` argument for the same source workspace.** The two manage the same list and conflict with each other.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "workspace_remote_state_consumers" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/workspace/remote_state_consumer"

  workspace_remote_state_consumers = {
    app_reads_network_state = {
      workspace_id = "ws-xxxxxxxxxx" # source workspace (remote_state_sharing = false)
      consumer_id  = "ws-yyyyyyyyyy" # workspace that may read the source workspace's state
    }
  }
}
```

### Composed With the Workspace Module

```hcl
module "workspaces" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/workspace"

  workspaces = {
    network = {
      environment_id       = "env-xxxxxxxxxx"
      remote_state_sharing = false # required on the source workspace
    }
    app = {
      environment_id = "env-xxxxxxxxxx"
    }
    data = {
      environment_id = "env-xxxxxxxxxx"
    }
  }
}

module "workspace_remote_state_consumers" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/workspace/remote_state_consumer"

  # One entry per consumer. The keys are caller-chosen logical names.
  workspace_remote_state_consumers = {
    app_reads_network = {
      workspace_id = module.workspaces.ids["network"]
      consumer_id  = module.workspaces.ids["app"]
    }
    data_reads_network = {
      workspace_id = module.workspaces.ids["network"]
      consumer_id  = module.workspaces.ids["data"]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- This is a standalone companion submodule to `modules/scalr/workspace`, following the single-resource-focus convention used by `modules/scalr/var_set/workspace_link`. It replaces the workspace module's deprecated `remote_state_consumers` argument, which the upstream provider has deprecated in favor of `remote_state_sharing` plus the `scalr_workspace_remote_state_consumer` resource. The deprecated argument is kept on the workspace module for backward compatibility, and the workspace module rejects an entry that sets both `remote_state_consumers` and `remote_state_sharing`.
- `workspace_remote_state_consumers` is a `map(object({...}))` keyed by a caller-chosen logical name, so a single module call can manage any number of source/consumer pairs (per [AGENTS.md §5](../../../../AGENTS.md)). Grant access to several consumers of the same source workspace by adding one entry per consumer.
- A workspace cannot consume its own state. A validation rejects any entry whose `consumer_id` equals its `workspace_id`, matching the provider's own check but failing earlier, at plan time and with the offending variable named. The check is skipped while either ID is still unknown (for example, a workspace created in the same run) and is enforced by the provider at apply time.
- Two further validations reject blank IDs and duplicate `workspace_id`/`consumer_id` pairs listed under different keys. The reverse pair (A reads B and B reads A) is a different grant and is allowed.
- Both IDs force replacement when changed. The resource has no update path; editing either ID on an existing entry removes the old grant and creates the new one.
- The resource ID has the format `<workspace_id>/<consumer_id>`, which is also the import ID: `tofu import 'module.workspace_remote_state_consumers.scalr_workspace_remote_state_consumer.this["app_reads_network"]' ws-xxxxxxxxxx/ws-yyyyyyyyyy`.
- Tests run offline with `mock_provider`, so `tofu test` needs no Scalr credentials.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
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
