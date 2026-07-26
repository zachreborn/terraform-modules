<a name="readme-top"></a>

## scalr/policy_group/linkage

Manages [`scalr_policy_group_linkage`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/policy_group_linkage) resources, which link a Scalr Policy Group to an Environment. This is a companion submodule to [`../`](../), which composes it automatically for entries in `policy_group_linkages`; it may also be called standalone.

### Prerequisites

- The policy group referenced by `policy_group_id` must already exist (e.g. created by the parent `scalr/policy_group` module, or externally).
- The environment referenced by `environment_id` must already exist.

### Usage

```hcl
module "policy_group_linkage" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/policy_group/linkage"

  linkages = {
    instance_types_prod = {
      policy_group_id = "pgrp-xxxxxxxxxx"
      environment_id   = "env-xxxxxxxxxx"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Notes / Design Decisions

- To manage a linkage, use either this resource (via this submodule) or the `environments` attribute of `scalr_policy_group` -- not both for the same policy group/environment pair.
- `linkages` is a `map(object({...}))` so callers can manage any number of linkages with a single module call.

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
| scalr_policy_group_linkage.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_linkages"></a> [linkages](#input\_linkages) | Map of scalr\_policy\_group\_linkage resources to create, keyed by a caller-chosen logical name.<br/>Fields:<br/>  - policy\_group\_id: (Required) ID of the policy group, in the format "pgrp-<RANDOM STRING>".<br/>  - environment\_id:  (Required) ID of the environment, in the format "env-<RANDOM STRING>". | <pre>map(object({<br/>    policy_group_id = string<br/>    environment_id  = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Policy Group Linkage IDs, keyed by the same keys as var.linkages. |
<!-- END_TF_DOCS -->
