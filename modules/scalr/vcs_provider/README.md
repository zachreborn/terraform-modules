<a name="readme-top"></a>

## scalr/vcs_provider

Manages [`scalr_vcs_provider`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/vcs_provider) resources, connecting Scalr to a version control system (GitHub, GitHub Enterprise, GitLab, GitLab Enterprise, or Bitbucket Enterprise) so environments can source workspaces from VCS-backed repositories.

### Prerequisites

- A personal access token for the target VCS provider, ready to pass via `vcs_provider_tokens` -- never inline it in `vcs_providers`.
  - GitHub token: https://github.com/settings/tokens/new?description=example-vcs-resouce&scopes=repo
  - GitLab token: https://gitlab.com/-/profile/personal_access_tokens?name=example-vcs-resouce&scopes=api,read_user,read_registry
- For self-hosted VCS types (`github_enterprise`, `gitlab_enterprise`, `bitbucket_enterprise`), the `url` field is required, and for `bitbucket_enterprise` the `username` field is also required.
- For self-hosted VCS providers connected via an agent, an existing agent pool ID to pass as `agent_pool_id`.

### Usage

```hcl
module "vcs_provider" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/vcs_provider"

  account_id = "acc-xxxxxxxxxx" # module-wide fallback; individual entries may override it

  vcs_providers = {
    github_main = {
      vcs_type     = "github"
      environments = ["*"]
    }

    gitlab_self_hosted = {
      name          = "gitlab-self-hosted"
      vcs_type      = "gitlab_enterprise"
      url           = "https://gitlab.example.com"
      agent_pool_id = "apool-xxxxxxxxxx"
    }
  }

  # Sensitive values, keyed the same as the entries above.
  vcs_provider_tokens = {
    github_main        = var.github_token        # e.g. from a secret manager
    gitlab_self_hosted = var.gitlab_self_hosted_token
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Notes / Design Decisions

- `vcs_providers` is a `map(object({...}))` so callers can manage any number of VCS providers with a single module call (per [AGENTS.md §5](../../../AGENTS.md)).
- **The token is split into a separate variable.** The required, sensitive `token` field is deliberately *not* part of `vcs_providers`. It lives in `vcs_provider_tokens`, keyed by the same logical key. This is necessary because `vcs_providers` is this module's `for_each` source, and OpenTofu/Terraform forbid using a sensitive collection as a `for_each` argument (the engine needs to see the map keys in the plan). Marking the whole `vcs_providers` map sensitive would break `for_each`; splitting the sensitive token into its own always-sensitive map avoids that while still keeping the real secret marked `sensitive = true`. This mirrors `provider_configuration_secrets` in [`modules/scalr/provider_configuration`](../provider_configuration).
- `name` defaults to the entry's map key via `coalesce(each.value.name, each.key)` when unset.
- `account_id` can be set per-entry, or omitted to fall back to the module-wide `var.account_id`. An entry's own `account_id` always takes precedence over the module-wide default.
- `environments` defaults to `["*"]` (shared with all environments) to match the most common usage pattern; override per-entry to scope a provider to specific environments.
- `draft_pr_runs_enabled` defaults to `false`, matching the upstream provider's default.

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
| scalr_vcs_provider.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | (Optional) Module-wide fallback account ID, in the format "acc-<RANDOM STRING>", used for any var.vcs\_providers entry that omits account\_id. | `string` | `null` | no |
| <a name="input_vcs_provider_tokens"></a> [vcs\_provider\_tokens](#input\_vcs\_provider\_tokens) | Map of sensitive personal access tokens for var.vcs\_providers, keyed by the same logical key.<br/>Kept in a separate, wholly `sensitive = true` variable so that var.vcs\_providers itself can<br/>remain non-sensitive (required, since it is the for\_each source for scalr\_vcs\_provider.this).<br/>Every entry in var.vcs\_providers must have a corresponding entry here, since the underlying<br/>provider requires a token for every VCS provider.<br/>  - GitHub token can be generated at<br/>    https://github.com/settings/tokens/new?description=example-vcs-resouce&scopes=repo<br/>  - GitLab token can be generated at<br/>    https://gitlab.com/-/profile/personal_access_tokens?name=example-vcs-resouce&scopes=api,read_user,read_registry | `map(string)` | `{}` | no |
| <a name="input_vcs_providers"></a> [vcs\_providers](#input\_vcs\_providers) | Map of Scalr VCS Providers (scalr\_vcs\_provider) to create, keyed by a caller-chosen logical<br/>name. Fields:<br/>  - name:                       (Optional) Name of the VCS provider. Defaults to the entry's<br/>                                map key.<br/>  - account\_id:                  (Optional) ID of the account, in the format<br/>                                "acc-<RANDOM STRING>". Falls back to var.account\_id when unset.<br/>  - agent\_pool\_id:                (Optional) The id of the agent pool to connect Scalr to a<br/>                                self-hosted VCS provider.<br/>  - comments\_enabled:             (Optional) Enable comments on pull requests for the VCS<br/>                                provider.<br/>  - draft\_pr\_runs\_enabled:        (Optional) Enable draft PR runs for the VCS provider.<br/>                                Defaults to false.<br/>  - environments:                 (Optional) Set of environment IDs the VCS provider is shared<br/>                                to. Use ["*"] to share with all environments. Defaults to<br/>                                ["*"].<br/>  - pr\_merge\_comments\_enabled:    (Optional) Enable comments after pull request merges for the<br/>                                VCS provider.<br/>  - url:                          (Optional) Required for self-hosted VCS providers.<br/>  - username:                     (Optional) Required for the "bitbucket\_enterprise" provider<br/>                                type.<br/>  - vcs\_type:                     (Optional) One of "github", "github\_enterprise", "gitlab",<br/>                                "gitlab\_enterprise", "bitbucket\_enterprise". Defaults to<br/>                                "github".<br/><br/>The sensitive personal access token for each entry is intentionally NOT part of this<br/>variable -- see var.vcs\_provider\_tokens. Keeping it out of this map lets var.vcs\_providers<br/>remain non-sensitive, which is required because it is this module's for\_each source<br/>(OpenTofu/Terraform disallow for\_each over a sensitive collection). | <pre>map(object({<br/>    name                      = optional(string)<br/>    account_id                = optional(string)<br/>    agent_pool_id             = optional(string)<br/>    comments_enabled          = optional(bool)<br/>    draft_pr_runs_enabled     = optional(bool, false)<br/>    environments              = optional(set(string), ["*"])<br/>    pr_merge_comments_enabled = optional(bool)<br/>    url                       = optional(string)<br/>    username                  = optional(string)<br/>    vcs_type                  = optional(string, "github")<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of VCS Provider IDs, keyed by the same keys as var.vcs\_providers. |
<!-- END_TF_DOCS -->
