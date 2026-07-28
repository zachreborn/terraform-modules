<a name="readme-top"></a>

## scalr/federated_environments

Manages [`scalr_federated_environments`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/federated_environments) resources -- the list of environments allowed to access a "hub" environment's federated resources in Scalr.

### Prerequisites

- The environment referenced by `environment_id` (the environment that federates access) must already exist.
- Every environment listed in `federated_environments` (unless using the `"*"` wildcard) must already exist.

### Usage

```hcl
module "federated_environments" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/federated_environments"

  federated_environments = {
    shared_services = {
      environment_id          = "env-xxxxxxxxxx"
      federated_environments  = ["env-yyyyyyyyyy", "env-zzzzzzzzzz"]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Notes / Design Decisions

- `federated_environments` is a `map(object({...}))` so callers can manage any number of federation entries with a single module call.
- Each entry is validated to ensure `environment_id` does not appear in its own `federated_environments` set (an environment cannot federate access to itself).
- Unlike most other Scalr resources, `scalr_federated_environments` does not expose a separate read-only `id` attribute in the upstream provider's documented schema; this module exposes pass-through outputs (`environment_ids`, `federated_environment_sets`) instead.

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
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_federated_environments.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_federated_environments"></a> [federated\_environments](#input\_federated\_environments) | Map of scalr\_federated\_environments resources to create, keyed by a caller-chosen logical<br/>name. Each entry manages the list of federated environments for one "hub" environment.<br/>Fields:<br/>  - environment\_id:         (Required) The ID of an environment that federates access to other<br/>                            environments, in the format "env-<RANDOM STRING>".<br/>  - federated\_environments: (Required) Set of environment identifiers that are allowed to<br/>                            access the environment that federates access. Use ["*"] to allow all<br/>                            environments. | <pre>map(object({<br/>    environment_id         = string<br/>    federated_environments = set(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_environment_ids"></a> [environment\_ids](#output\_environment\_ids) | Map of the hub environment\_id managed by each entry, keyed by the same keys as var.federated\_environments. |
| <a name="output_federated_environment_sets"></a> [federated\_environment\_sets](#output\_federated\_environment\_sets) | Map of the federated\_environments set managed by each entry, keyed by the same keys as var.federated\_environments. |
<!-- END_TF_DOCS -->
