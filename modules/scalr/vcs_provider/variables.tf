###########################
# Resource Variables
###########################
variable "vcs_providers" {
  description = <<-EOT
    Map of Scalr VCS Providers (scalr_vcs_provider) to create, keyed by a caller-chosen logical
    name. Fields:
      - name:                       (Optional) Name of the VCS provider. Defaults to the entry's
                                    map key.
      - account_id:                  (Optional) ID of the account, in the format
                                    "acc-<RANDOM STRING>". Falls back to var.account_id when unset.
      - agent_pool_id:                (Optional) The id of the agent pool to connect Scalr to a
                                    self-hosted VCS provider.
      - comments_enabled:             (Optional) Enable comments on pull requests for the VCS
                                    provider.
      - draft_pr_runs_enabled:        (Optional) Enable draft PR runs for the VCS provider.
                                    Defaults to false.
      - environments:                 (Optional) Set of environment IDs the VCS provider is shared
                                    to. Use ["*"] to share with all environments. Defaults to
                                    ["*"].
      - pr_merge_comments_enabled:    (Optional) Enable comments after pull request merges for the
                                    VCS provider.
      - url:                          (Optional) Required for self-hosted VCS providers.
      - username:                     (Optional) Required for the "bitbucket_enterprise" provider
                                    type.
      - vcs_type:                     (Optional) One of "github", "github_enterprise", "gitlab",
                                    "gitlab_enterprise", "bitbucket_enterprise". Defaults to
                                    "github".

    The sensitive personal access token for each entry is intentionally NOT part of this
    variable -- see var.vcs_provider_tokens. Keeping it out of this map lets var.vcs_providers
    remain non-sensitive, which is required because it is this module's for_each source
    (OpenTofu/Terraform disallow for_each over a sensitive collection).
  EOT
  type = map(object({
    name                      = optional(string)
    account_id                = optional(string)
    agent_pool_id             = optional(string)
    comments_enabled          = optional(bool)
    draft_pr_runs_enabled     = optional(bool, false)
    environments              = optional(set(string), ["*"])
    pr_merge_comments_enabled = optional(bool)
    url                       = optional(string)
    username                  = optional(string)
    vcs_type                  = optional(string, "github")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.vcs_providers : contains(
        ["github", "github_enterprise", "gitlab", "gitlab_enterprise", "bitbucket_enterprise"],
        v.vcs_type
      )
    ])
    error_message = "Each vcs_providers vcs_type must be one of \"github\", \"github_enterprise\", \"gitlab\", \"gitlab_enterprise\", or \"bitbucket_enterprise\"."
  }
}

variable "vcs_provider_tokens" {
  description = <<-EOT
    Map of sensitive personal access tokens for var.vcs_providers, keyed by the same logical key.
    Kept in a separate, wholly `sensitive = true` variable so that var.vcs_providers itself can
    remain non-sensitive (required, since it is the for_each source for scalr_vcs_provider.this).
    Every entry in var.vcs_providers must have a corresponding entry here, since the underlying
    provider requires a token for every VCS provider.
      - GitHub token can be generated at
        https://github.com/settings/tokens/new?description=example-vcs-resouce&scopes=repo
      - GitLab token can be generated at
        https://gitlab.com/-/profile/personal_access_tokens?name=example-vcs-resouce&scopes=api,read_user,read_registry
  EOT
  type        = map(string)
  sensitive   = true
  default     = {}
}

###########################
# General Variables
###########################
variable "account_id" {
  description = "(Optional) Module-wide fallback account ID, in the format \"acc-<RANDOM STRING>\", used for any var.vcs_providers entry that omits account_id."
  type        = string
  default     = null
}
