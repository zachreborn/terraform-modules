<a name="readme-top"></a>

## scalr/module/namespace

Manages [`scalr_module_namespace`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/module_namespace) resources -- namespaces within the Scalr Private Module Registry. This is a companion submodule to [`../`](../), which composes it automatically for entries in `module_namespaces`; it may also be called standalone.

### Prerequisites

- None -- module namespaces are a top-level Private Module Registry construct.

### Usage

```hcl
module "module_namespace" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/module/namespace"

  module_namespaces = {
    shared = {
      is_shared = true
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Notes / Design Decisions

- `module_namespaces` is a `map(object({...}))` so callers can manage any number of namespaces with a single module call.

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
| scalr_module_namespace.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_module_namespaces"></a> [module\_namespaces](#input\_module\_namespaces) | Map of Scalr Module Namespaces (scalr\_module\_namespace) to create, keyed by a caller-chosen<br/>logical name. Fields:<br/>  - name:         (Optional) Name of the module namespace. Defaults to the entry's map key.<br/>  - environments: (Optional) Set of environment IDs associated with the module namespace.<br/>  - is\_shared:    (Optional) Whether the module namespace is shared.<br/>  - owners:       (Optional) Set of team IDs that own the module namespace. | <pre>map(object({<br/>    name         = optional(string)<br/>    environments = optional(set(string))<br/>    is_shared    = optional(bool)<br/>    owners       = optional(set(string))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Module Namespace IDs, keyed by the same keys as var.module\_namespaces. |
<!-- END_TF_DOCS -->
