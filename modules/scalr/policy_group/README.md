<a name="readme-top"></a>

## scalr/policy_group

Manages [`scalr_policy_group`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/policy_group) resources (OPA policy groups sourced from a VCS repository) in Scalr, and composes the companion [`./linkage`](./linkage) submodule to optionally manage [`scalr_policy_group_linkage`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/policy_group_linkage) resources that bind a policy group to an environment.

### Prerequisites

- A `scalr_vcs_provider` (see `modules/scalr` root module) must already exist; its ID is passed in as `vcs_repo`'s `vcs_provider_id`.
- The VCS repository referenced by `vcs_repo.identifier` must contain the OPA policies (and optionally a `common_functions_folder`) to enforce.
- Any `environment_id` referenced by `policy_group_linkages` (directly, or via a `scalr_environment` resource elsewhere) must already exist.

### Usage

```hcl
module "policy_group" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/policy_group"

  policy_groups = {
    instance_types = {
      account_id      = "acc-xxxxxxxxxx"
      vcs_provider_id = "vcs-xxxxxxxxxx"
      opa_version     = "0.29.4"
      vcs_repo = {
        identifier = "my-org/policies"
        path       = "policies/instance"
        branch     = "main"
      }
    }
  }

  # Optional: manage policy group <-> environment linkages via the companion submodule
  # instead of (or in addition to) the policy_groups.environments attribute.
  policy_group_linkages = {
    instance_types_prod = {
      policy_group_key = "instance_types" # resolved internally to the policy group created above
      environment_id   = "env-xxxxxxxxxx"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Notes / Design Decisions

- `policy_groups` is a `map(object({...}))` so callers can manage any number of policy groups with a single module call (per [AGENTS.md §5](../../../AGENTS.md)).
- A policy group's environment linkage can be managed two ways, matching the upstream provider: inline via `policy_groups.<key>.environments`, or explicitly via `policy_group_linkages` (backed by the `./linkage` companion submodule). Do not manage the same policy group/environment pair both ways simultaneously.
- `policy_group_linkages` entries reference a policy group either by `policy_group_key` (an entry created by this same module call -- resolved internally to its ID) or by a literal, externally-managed `policy_group_id`. Exactly one of the two must be set.
- This module accepts `account_id` per-entry rather than resolving it internally via `data.scalr_current_account`, so `tofu test` can run fully offline with `mock_provider`.

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
| <a name="module_linkage"></a> [linkage](#module\_linkage) | ./linkage | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| scalr_policy_group.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_policy_group_linkages"></a> [policy\_group\_linkages](#input\_policy\_group\_linkages) | Map of scalr\_policy\_group\_linkage resources to create, keyed by a caller-chosen logical name.<br/>Each entry links one policy group to one environment. Set exactly one of:<br/>  - policy\_group\_key: The map key of an entry in var.policy\_groups whose ID is resolved internally<br/>                      by this module (composition wiring).<br/>  - policy\_group\_id:  A literal, externally-managed policy group ID (format "pgrp-<RANDOM STRING>").<br/>Fields:<br/>  - environment\_id: (Required) ID of the environment, in the format "env-<RANDOM STRING>". | <pre>map(object({<br/>    policy_group_key = optional(string)<br/>    policy_group_id  = optional(string)<br/>    environment_id   = string<br/>  }))</pre> | `{}` | no |
| <a name="input_policy_groups"></a> [policy\_groups](#input\_policy\_groups) | Map of Scalr Policy Groups (scalr\_policy\_group) to create, keyed by a caller-chosen logical<br/>name (e.g. "instance\_types"). Fields:<br/>  - name:                    (Optional) Name of the policy group. Defaults to the entry's map key.<br/>  - account\_id:               (Optional) The identifier of the Scalr account, in the format "acc-<RANDOM STRING>".<br/>  - vcs\_provider\_id:          (Required) The identifier of a VCS provider, in the format "vcs-<RANDOM STRING>".<br/>  - vcs\_repo.identifier:      (Required) The reference to the VCS repository, in the format ":org/:repo".<br/>  - vcs\_repo.branch:          (Optional) The branch of the repository the policy group is associated with.<br/>                              Defaults to the repository's default branch when unset.<br/>  - vcs\_repo.path:            (Optional) The subdirectory of the VCS repository where OPA policies are<br/>                              stored. Defaults to the repository root when unset.<br/>  - opa\_version:              (Optional) The version of Open Policy Agent to run policies against.<br/>                              Defaults to the system default version when unset.<br/>  - common\_functions\_folder:  (Optional) An absolute path from the repository root to the folder that<br/>                              contains common rego functions.<br/>  - environments:             (Optional) Set of environment IDs the policy group is linked to. Use<br/>                              ["*"] to enforce in all environments. To manage linkages, use either this<br/>                              attribute or var.policy\_group\_linkages (backed by the companion<br/>                              ./linkage submodule) -- not both for the same environment. | <pre>map(object({<br/>    name            = optional(string)<br/>    account_id      = optional(string)<br/>    vcs_provider_id = string<br/>    vcs_repo = object({<br/>      identifier = string<br/>      branch     = optional(string)<br/>      path       = optional(string)<br/>    })<br/>    opa_version             = optional(string)<br/>    common_functions_folder = optional(string)<br/>    environments            = optional(set(string))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_error_messages"></a> [error\_messages](#output\_error\_messages) | Map of detailed Policy Group processing error messages (if any), keyed by the same keys as var.policy\_groups. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Policy Group IDs, keyed by the same keys as var.policy\_groups. |
| <a name="output_linkage_ids"></a> [linkage\_ids](#output\_linkage\_ids) | Map of Policy Group Linkage IDs (from the companion ./linkage submodule), keyed by the same keys as var.policy\_group\_linkages. |
| <a name="output_policies"></a> [policies](#output\_policies) | Map of the list of OPA policies each Policy Group verifies, keyed by the same keys as var.policy\_groups. |
| <a name="output_resolved_linkages"></a> [resolved\_linkages](#output\_resolved\_linkages) | Map of policy\_group\_id/environment\_id pairs actually passed to the companion ./linkage submodule, keyed by the same keys as var.policy\_group\_linkages. Useful to verify composition wiring. |
| <a name="output_statuses"></a> [statuses](#output\_statuses) | Map of Policy Group system statuses, keyed by the same keys as var.policy\_groups. |
<!-- END_TF_DOCS -->
