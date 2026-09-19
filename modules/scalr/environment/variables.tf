###########################
# Resource Variables
###########################
variable "environments" {
  description = <<-EOT
    (Optional) Map of Scalr Environments (scalr_environment) to create, keyed by a caller-chosen
    logical name (e.g. "production"). Each entry:
      - name:                             (Optional) Name of the environment. Defaults to the
                                          entry's map key when unset.
      - account_id:                       (Optional) ID of the account, in the format 'acc-'.
                                          Falls back to var.account_id when unset.
      - default_provider_configurations:  (Optional) Set of IDs of provider configurations, used
                                          in the environment workspaces by default.
      - default_workspace_agent_pool_id:  (Optional) Default agent pool that will be set for the
                                          entire environment. It will be used by a workspace if no
                                          other pool is explicitly linked.
      - federated_environments:           (Optional, Deprecated upstream) Set of environment
                                          identifiers that are allowed to access this environment.
                                          Use ["*"] to share with all environments.
      - mask_sensitive_output:            (Optional) Enable masking of the sensitive console
                                          output. Defaults to true.
      - remote_backend:                   (Optional) If Scalr exports the remote backend
                                          configuration and state storage for your infrastructure
                                          management. Disabling this feature will also prevent the
                                          ability to perform state locking, which ensures that
                                          concurrent operations do not conflict. Additionally, it
                                          will disable the capability to initiate CLI-driven runs
                                          through Scalr. Defaults to true.
      - remote_backend_overridable:       (Optional) Indicates if the remote backend configuration
                                          can be overridden on the workspace level. Defaults to
                                          false.
      - storage_profile_id:               (Optional) The storage profile for this environment. If
                                          not set, the account's default storage profile will be
                                          used.
      - tag_ids:                          (Optional) Set of tag IDs associated with the
                                          environment.
  EOT
  type = map(object({
    name                            = optional(string)
    account_id                      = optional(string)
    default_provider_configurations = optional(set(string))
    default_workspace_agent_pool_id = optional(string)
    federated_environments          = optional(set(string))
    mask_sensitive_output           = optional(bool, true)
    remote_backend                  = optional(bool, true)
    remote_backend_overridable      = optional(bool, false)
    storage_profile_id              = optional(string)
    tag_ids                         = optional(set(string))
  }))
  default = {}
}

###########################
# General Variables
###########################
variable "account_id" {
  description = "(Optional) Default ID of the account, in the format 'acc-', used for any environments entry that does not set its own account_id."
  type        = string
  default     = null
}
