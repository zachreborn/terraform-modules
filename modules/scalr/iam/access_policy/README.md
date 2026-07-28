<a name="readme-top"></a>

# scalr/iam/access_policy

Manages [`scalr_access_policy`](https://github.com/Scalr/terraform-provider-scalr/blob/master/docs/resources/access_policy.md) resources -- Scalr IAM access policies binding a subject (user, team, or service account) to a set of roles at a given scope (account, environment, or workspace).

## Prerequisites

- A Scalr account and an authenticated `scalr` provider (see the [Scalr Terraform Provider docs](https://docs.scalr.io/terraform-provider)).
- The `role_ids` referenced by each entry must already exist -- provision them with `modules/scalr/iam/role` (or use Scalr's built-in system roles) first.
- The `subject.id` (a user, team, or service account ID) and `scope.id` (an account, environment, or workspace ID) referenced by each entry must already exist.

## Usage

```hcl
module "roles" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/iam/role"

  roles = {
    reader = {
      permissions = ["*:read"]
    }
  }
}

module "access_policies" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/iam/access_policy"

  access_policies = {
    team_read_all_on_acc_scope = {
      role_ids = [module.roles.ids["reader"]]
      subject = {
        type = "team"
        id   = "team-xxxxxxxxxx"
      }
      scope = {
        type = "account"
        id   = "acc-xxxxxxxxxx"
      }
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `access_policies` is a `map(object({...}))` so callers can manage many policies via a single module call. Unlike other Scalr IAM resources in this repository, `scalr_access_policy` has no `account_id` attribute of its own -- account scoping happens entirely through the `scope` block.
- `subject.type` is validated against the exact enum the provider supports (`user`, `team`, `service_account`); `scope.type` is validated against (`account`, `environment`, `workspace`). Both validations fail fast at plan time instead of surfacing a provider-side API error.
- `role_ids` is typed as `set(string)` to mirror the provider's "Set of String" attribute exactly, and is validated to be non-empty since a policy with no roles grants no access.

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
| scalr_access_policy.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_policies"></a> [access\_policies](#input\_access\_policies) | (Optional) Map of Scalr IAM access policies to create, keyed by a caller-chosen logical name<br/>(e.g. "team\_read\_all\_on\_acc\_scope"). Each entry:<br/>  - role\_ids: (Required) Set of scalr\_role IDs to grant. Must be non-empty.<br/>  - subject:  (Required) Block identifying who the policy applies to:<br/>                - type: (Required) One of "user", "team", or "service\_account".<br/>                - id:   (Required) The subject ID -- "user-" for a user, "team-" for a team, or<br/>                        "sa-" for a service account.<br/>  - scope:    (Required) Block identifying where the policy applies:<br/>                - type: (Required) One of "account", "environment", or "workspace".<br/>                - id:   (Required) The scope ID -- "acc-" for account, "env-" for environment, or<br/>                        "ws-" for workspace. | <pre>map(object({<br/>    role_ids = set(string)<br/>    subject = object({<br/>      type = string<br/>      id   = string<br/>    })<br/>    scope = object({<br/>      type = string<br/>      id   = string<br/>    })<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Access Policy IDs, keyed by the same keys as var.access\_policies. |
| <a name="output_is_system"></a> [is\_system](#output\_is\_system) | Map of booleans indicating whether each access policy is a built-in, read-only system policy that cannot be updated or deleted, keyed by the same keys as var.access\_policies. |
<!-- END_TF_DOCS -->
