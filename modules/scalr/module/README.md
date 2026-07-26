<a name="readme-top"></a>

## scalr/module

Manages [`scalr_module`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/module) resources (entries in the Scalr Private Module Registry, sourced from a VCS repository), and composes the companion [`./namespace`](./namespace) submodule to optionally manage [`scalr_module_namespace`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/module_namespace) resources.

### Prerequisites

- A `scalr_vcs_provider` (see `modules/scalr` root module) must already exist; its ID is passed in as `vcs_provider_id`.
- The VCS repository referenced by `vcs_repo.identifier` must contain the module source at `vcs_repo.path`, ideally following the `terraform-<provider>-<name>` naming convention.

### Usage

```hcl
module "module" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/module"

  # Optional: manage module namespaces via the companion submodule.
  module_namespaces = {
    shared = {
      is_shared = true
    }
  }

  modules = {
    vpc = {
      vcs_provider_id = "vcs-xxxxxxxxxx"
      namespace_key   = "shared" # resolved internally to the namespace created above
      vcs_repo = {
        identifier = "my-org/terraform-aws-vpc"
        path       = "."
        tag_prefix = "aws/"
      }
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Notes / Design Decisions

- `modules` is a `map(object({...}))` so callers can manage any number of registry modules with a single module call (per [AGENTS.md §5](../../../AGENTS.md)).
- The upstream provider deprecates `account_id`/`environment_id` on `scalr_module` in favor of `namespace_id`. This module still exposes `account_id`/`environment_id` per-entry for full argument coverage of the provider resource, but new configurations should prefer `namespace_id` (a literal, externally-managed namespace ID) or `namespace_key` (a reference, by key, to an entry in `module_namespaces` created by this same module call). `namespace_id`/`namespace_key` may not be combined with `environment_id`, matching the upstream provider's documented conflict.
- `namespace_key` mirrors the `parent_key` pattern used elsewhere in this repository (e.g. `modules/aws/organizations/ou`): it lets a caller reference a sibling resource created by the same module call without knowing its ID ahead of time.

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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_namespace"></a> [namespace](#module\_namespace) | ./namespace | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| scalr_module.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_module_namespaces"></a> [module\_namespaces](#input\_module\_namespaces) | Map of Scalr Module Namespaces (scalr\_module\_namespace) to create via the companion<br/>./namespace submodule, keyed by a caller-chosen logical name. See ./namespace/variables.tf<br/>for the full field list. Reference an entry from var.modules by setting that entry's<br/>namespace\_key to this map's key. | <pre>map(object({<br/>    name         = optional(string)<br/>    environments = optional(set(string))<br/>    is_shared    = optional(bool)<br/>    owners       = optional(set(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_modules"></a> [modules](#input\_modules) | Map of Scalr Private Module Registry entries (scalr\_module) to create, keyed by a<br/>caller-chosen logical name. Fields:<br/>  - vcs\_provider\_id:     (Required) The identifier of a VCS provider, in the format "vcs-<RANDOM STRING>".<br/>  - vcs\_repo.identifier: (Required) The identifier of a VCS repository, in the format ":org/:repo"<br/>                        (":org/:project/:name" for Azure DevOps).<br/>  - vcs\_repo.path:       (Optional) The path to the root module folder. Expected to have the format<br/>                        "<path>/terraform-<provider\_name>-<module\_name>".<br/>  - vcs\_repo.tag\_prefix: (Optional) Registry ignores tags which do not match this prefix, e.g. "aws/".<br/>  - namespace\_id:        (Optional) A literal, externally-managed module namespace ID (format<br/>                        "modns-<RANDOM STRING>"). Conflicts with environment\_id and namespace\_key.<br/>  - namespace\_key:       (Optional) The map key of an entry in var.module\_namespaces whose ID is<br/>                        resolved internally by this module (composition wiring). Conflicts with<br/>                        environment\_id and namespace\_id.<br/>  - module\_provider:     (Optional) Module provider name, e.g. "aws", "azurerm", "google".<br/>  - name:                (Optional) Name of the module, e.g. "rds", "compute", "kubernetes-engine".<br/>  - account\_id:          (Optional, DEPRECATED by the upstream provider in favor of namespace\_id/<br/>                        namespace\_key) The identifier of the account, in the format "acc-<RANDOM STRING>".<br/>                        If set and namespace\_id/namespace\_key are not, the module is registered<br/>                        globally, available across the whole installation. Still exposed here for<br/>                        full argument coverage of the provider resource.<br/>  - environment\_id:      (Optional, DEPRECATED by the upstream provider in favor of namespace\_id/<br/>                        namespace\_key) The identifier of an environment, in the format "env-<RANDOM STRING>".<br/>                        Conflicts with namespace\_id/namespace\_key. Still exposed here for full<br/>                        argument coverage of the provider resource. | <pre>map(object({<br/>    vcs_provider_id = string<br/>    vcs_repo = object({<br/>      identifier = string<br/>      path       = optional(string)<br/>      tag_prefix = optional(string)<br/>    })<br/>    namespace_id    = optional(string)<br/>    namespace_key   = optional(string)<br/>    module_provider = optional(string)<br/>    name            = optional(string)<br/>    account_id      = optional(string)<br/>    environment_id  = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Module IDs, keyed by the same keys as var.modules. |
| <a name="output_namespace_ids"></a> [namespace\_ids](#output\_namespace\_ids) | Map of Module Namespace IDs (from the companion ./namespace submodule), keyed by the same keys as var.module\_namespaces. |
| <a name="output_resolved_namespace_ids"></a> [resolved\_namespace\_ids](#output\_resolved\_namespace\_ids) | Map of the namespace\_id actually passed to each scalr\_module entry, keyed by the same keys as var.modules. Useful to verify composition wiring. |
| <a name="output_sources"></a> [sources](#output\_sources) | Map of the source of each remote module in the private registry (e.g. "env-xxxx/aws/vpc"), keyed by the same keys as var.modules. |
| <a name="output_statuses"></a> [statuses](#output\_statuses) | Map of Module system statuses, keyed by the same keys as var.modules. |
<!-- END_TF_DOCS -->
