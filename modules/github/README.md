<a name="readme-top"></a>

## github

Manages GitHub repository settings through reusable profiles and sparse repository overrides. Inventory entries remain reviewable data until a caller explicitly changes their `management_stage` to `managed`.

The module does not accept credentials. Configure the `integrations/github` provider in the root module with environment-based GitHub App authentication.

### Prerequisites

- Configure an `integrations/github` provider for the target GitHub owner.
- Capture a reviewed `change_control` API snapshot for `organization_policy` before enabling supplemental approval rules.
- Confirm that the provider identity can read and update every repository setting selected by the profiles.

### Usage

```hcl
module "github" {
  source = "github.com/zachreborn/terraform-modules//modules/github"

  profiles = {
    aws_dev = {
      visibility             = "private"
      has_issues             = true
      allow_squash_merge     = true
      delete_branch_on_merge = true
      topics                 = ["aws", "opentofu"]

      security_and_analysis = {
        advanced_security               = "enabled"
        secret_scanning                 = "enabled"
        secret_scanning_push_protection = "enabled"
      }
    }
    aws_test      = {}
    aws_prod      = {}
    control_plane = {}
    factory       = {}
  }

  repositories = {
    aws_dev_example = {
      profile          = "aws_dev"
      management_stage = "managed"

      overrides = {
        description = "Example development account"
        security_and_analysis = {
          secret_scanning_push_protection = "disabled"
        }
      }

      supplemental_rules = {
        extra_status_checks = ["OpenTofu / plan"]
        required_approvals  = 2
      }
    }
  }

  organization_policy = {
    ruleset_name               = "change_control"
    minimum_required_approvals = 1
    verified_at                = "2026-09-14T10:00:00Z"
  }
}
```

### Import-first adoption

1. Export the current repository settings through an authenticated GitHub API read.
2. Put shared current values in one of the five profiles and differences in sparse `overrides`.
3. Start each repository with `management_stage = "inventory"`.
4. Review the resolved values against the export.
5. Change the entry to `managed` in the same change that imports it:

```shell
tofu import 'module.github.github_repository.this["aws_dev_example"]' aws_dev_example
```

Require the adoption plan to show only imports. Resolve every settings update before apply.

### Organization policy coexistence

The organization `change_control` ruleset remains authoritative. This module neither queries nor manages it because the selected provider has no organization-ruleset data source.

Refresh `organization_policy` from a reviewed API snapshot before changing supplemental approvals. Supplemental repository rules can add status checks or an approval count that is not lower than the observed organization count. The module rejects bypass actors and never renders a bypass block.

### Repository retirement

Every managed repository has `lifecycle.prevent_destroy = true`. Do not remove a managed entry as a routine retirement action.

1. Approve a retirement change that names the repository, reason, owner, and retirement window. Keep configuration and state unchanged.
2. Back up state, then remove the exact repository address from state with an authorized and audited state operation.
3. Verify that the GitHub repository still exists and its settings are unchanged.
4. In a second change, remove the inventory entry and any empty supplemental rules. Require a no-op plan.

Never disable `prevent_destroy` or use repository deletion or automatic archiving as a retirement shortcut.

### Notes / design decisions

- OpenTofu 1.9 or newer is required for cross-variable validation.
- `integrations/github` 6.11.0 or newer is required. Version 6.11.0 first supports approval-only supplemental rulesets without duplicating organization merge-method policy.
- Profiles and overrides expose every effective `github_repository` argument in provider 6.11.0. Schema fields that are not serialized to GitHub API requests are intentionally omitted. Deprecated arguments remain available only to preserve existing settings during import; do not select them for new repositories.
- The repository ruleset interface is intentionally restricted to additive checks and approvals. It does not expose the provider's weakening, bypass, or unrelated rule options.
- Topics are trimmed, lowercased, deduplicated, and sorted. Supplemental status-check names are trimmed, deduplicated, and sorted.
- A sparse nested `security_and_analysis` override changes only named fields.
- GitHub always enables advanced security on public repositories. Leave `advanced_security` unset for public repositories as required by the provider.
- Repository merge-method reads can require GitHub App repository `Contents: write` permission in addition to repository `Administration: read/write`. Verify the exact installation permissions before adoption.

<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 6.11.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_github"></a> [github](#provider\_github) | >= 6.11.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [github_repository.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) | resource |
| [github_repository_ruleset.supplemental](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_organization_policy"></a> [organization\_policy](#input\_organization\_policy) | Reviewed snapshot guard for the authoritative organization change\_control ruleset. | <pre>object({<br/>    ruleset_name               = string<br/>    minimum_required_approvals = number<br/>    verified_at                = string<br/>  })</pre> | n/a | yes |
| <a name="input_profiles"></a> [profiles](#input\_profiles) | Repository setting profiles keyed by profile name. The map must contain aws\_dev, aws\_test,<br/>aws\_prod, control\_plane, and factory. Every setting is optional so an import-first caller can<br/>represent the current GitHub value without forcing unrelated standardization. | <pre>map(object({<br/>    description                             = optional(string)<br/>    homepage_url                            = optional(string)<br/>    fork                                    = optional(string)<br/>    source_owner                            = optional(string)<br/>    source_repo                             = optional(string)<br/>    private                                 = optional(bool)<br/>    visibility                              = optional(string)<br/>    topics                                  = optional(set(string))<br/>    has_issues                              = optional(bool)<br/>    has_projects                            = optional(bool)<br/>    has_wiki                                = optional(bool)<br/>    has_downloads                           = optional(bool)<br/>    has_discussions                         = optional(bool)<br/>    is_template                             = optional(bool)<br/>    allow_merge_commit                      = optional(bool)<br/>    allow_squash_merge                      = optional(bool)<br/>    allow_rebase_merge                      = optional(bool)<br/>    allow_auto_merge                        = optional(bool)<br/>    allow_forking                           = optional(bool)<br/>    allow_update_branch                     = optional(bool)<br/>    delete_branch_on_merge                  = optional(bool)<br/>    web_commit_signoff_required             = optional(bool)<br/>    squash_merge_commit_title               = optional(string)<br/>    squash_merge_commit_message             = optional(string)<br/>    merge_commit_title                      = optional(string)<br/>    merge_commit_message                    = optional(string)<br/>    vulnerability_alerts                    = optional(bool)<br/>    ignore_vulnerability_alerts_during_read = optional(bool)<br/>    auto_init                               = optional(bool)<br/>    gitignore_template                      = optional(string)<br/>    license_template                        = optional(string)<br/>    default_branch                          = optional(string)<br/>    archived                                = optional(bool)<br/>    archive_on_destroy                      = optional(bool)<br/><br/>    pages = optional(object({<br/>      build_type = optional(string)<br/>      cname      = optional(string)<br/>      source = optional(object({<br/>        branch = string<br/>        path   = optional(string)<br/>      }))<br/>    }))<br/><br/>    security_and_analysis = optional(object({<br/>      advanced_security               = optional(string)<br/>      secret_scanning                 = optional(string)<br/>      secret_scanning_push_protection = optional(string)<br/>    }))<br/><br/>    template = optional(object({<br/>      owner                = string<br/>      repository           = string<br/>      include_all_branches = optional(bool)<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Repository inventory keyed by exact GitHub repository name.<br/>  - profile: One key from profiles.<br/>  - management\_stage: inventory records reviewable data; managed creates a resource address.<br/>  - overrides: Sparse repository settings. Nested security settings merge field by field.<br/>  - supplemental\_rules: Optional additive checks or an approval count that cannot be lower than<br/>    organization\_policy.minimum\_required\_approvals.<br/>  - supplemental\_rules.bypass\_actors: Reserved rejection guard. It must remain empty because this<br/>    module never renders bypass actors. | <pre>map(object({<br/>    profile          = string<br/>    management_stage = string<br/><br/>    overrides = optional(object({<br/>      description                             = optional(string)<br/>      homepage_url                            = optional(string)<br/>      fork                                    = optional(string)<br/>      source_owner                            = optional(string)<br/>      source_repo                             = optional(string)<br/>      private                                 = optional(bool)<br/>      visibility                              = optional(string)<br/>      topics                                  = optional(set(string))<br/>      has_issues                              = optional(bool)<br/>      has_projects                            = optional(bool)<br/>      has_wiki                                = optional(bool)<br/>      has_downloads                           = optional(bool)<br/>      has_discussions                         = optional(bool)<br/>      is_template                             = optional(bool)<br/>      allow_merge_commit                      = optional(bool)<br/>      allow_squash_merge                      = optional(bool)<br/>      allow_rebase_merge                      = optional(bool)<br/>      allow_auto_merge                        = optional(bool)<br/>      allow_forking                           = optional(bool)<br/>      allow_update_branch                     = optional(bool)<br/>      delete_branch_on_merge                  = optional(bool)<br/>      web_commit_signoff_required             = optional(bool)<br/>      squash_merge_commit_title               = optional(string)<br/>      squash_merge_commit_message             = optional(string)<br/>      merge_commit_title                      = optional(string)<br/>      merge_commit_message                    = optional(string)<br/>      vulnerability_alerts                    = optional(bool)<br/>      ignore_vulnerability_alerts_during_read = optional(bool)<br/>      auto_init                               = optional(bool)<br/>      gitignore_template                      = optional(string)<br/>      license_template                        = optional(string)<br/>      default_branch                          = optional(string)<br/>      archived                                = optional(bool)<br/>      archive_on_destroy                      = optional(bool)<br/><br/>      pages = optional(object({<br/>        build_type = optional(string)<br/>        cname      = optional(string)<br/>        source = optional(object({<br/>          branch = optional(string)<br/>          path   = optional(string)<br/>        }))<br/>      }))<br/><br/>      security_and_analysis = optional(object({<br/>        advanced_security               = optional(string)<br/>        secret_scanning                 = optional(string)<br/>        secret_scanning_push_protection = optional(string)<br/>      }))<br/><br/>      template = optional(object({<br/>        owner                = optional(string)<br/>        repository           = optional(string)<br/>        include_all_branches = optional(bool)<br/>      }))<br/>    }), {})<br/><br/>    supplemental_rules = optional(object({<br/>      extra_status_checks = optional(set(string), [])<br/>      required_approvals  = optional(number)<br/>      bypass_actors = optional(set(object({<br/>        actor_id   = number<br/>        actor_type = string<br/>      })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_repository_full_names"></a> [repository\_full\_names](#output\_repository\_full\_names) | Map of owner/repository names for managed repositories, keyed by exact repository name. |
| <a name="output_repository_git_clone_urls"></a> [repository\_git\_clone\_urls](#output\_repository\_git\_clone\_urls) | Map of anonymous Git clone URLs for managed repositories, keyed by exact repository name. |
| <a name="output_repository_html_urls"></a> [repository\_html\_urls](#output\_repository\_html\_urls) | Map of GitHub web URLs for managed repositories, keyed by exact repository name. |
| <a name="output_repository_http_clone_urls"></a> [repository\_http\_clone\_urls](#output\_repository\_http\_clone\_urls) | Map of HTTPS clone URLs for managed repositories, keyed by exact repository name. |
| <a name="output_repository_ids"></a> [repository\_ids](#output\_repository\_ids) | Map of GitHub numeric repository IDs for managed repositories, keyed by exact repository name. |
| <a name="output_repository_node_ids"></a> [repository\_node\_ids](#output\_repository\_node\_ids) | Map of GitHub GraphQL node IDs for managed repositories, keyed by exact repository name. |
| <a name="output_repository_pages"></a> [repository\_pages](#output\_repository\_pages) | Map of computed GitHub Pages metadata for managed repositories, keyed by exact repository name. |
| <a name="output_repository_primary_languages"></a> [repository\_primary\_languages](#output\_repository\_primary\_languages) | Map of primary languages for managed repositories, keyed by exact repository name. |
| <a name="output_repository_ssh_clone_urls"></a> [repository\_ssh\_clone\_urls](#output\_repository\_ssh\_clone\_urls) | Map of SSH clone URLs for managed repositories, keyed by exact repository name. |
| <a name="output_repository_svn_urls"></a> [repository\_svn\_urls](#output\_repository\_svn\_urls) | Map of Subversion URLs for managed repositories, keyed by exact repository name. |
| <a name="output_supplemental_ruleset_ids"></a> [supplemental\_ruleset\_ids](#output\_supplemental\_ruleset\_ids) | Map of GitHub ruleset IDs for repositories with supplemental rules, keyed by exact repository name. |
<!-- END_TF_DOCS -->
