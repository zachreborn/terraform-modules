###########################
# Resource Variables
###########################
variable "modules" {
  description = <<-EOT
    Map of Scalr Private Module Registry entries (scalr_module) to create, keyed by a
    caller-chosen logical name. Fields:
      - vcs_provider_id:     (Required) The identifier of a VCS provider, in the format "vcs-<RANDOM STRING>".
      - vcs_repo.identifier: (Required) The identifier of a VCS repository, in the format ":org/:repo"
                            (":org/:project/:name" for Azure DevOps).
      - vcs_repo.path:       (Optional) The path to the root module folder. Expected to have the format
                            "<path>/terraform-<provider_name>-<module_name>".
      - vcs_repo.tag_prefix: (Optional) Registry ignores tags which do not match this prefix, e.g. "aws/".
      - namespace_id:        (Optional) A literal, externally-managed module namespace ID (format
                            "modns-<RANDOM STRING>"). Conflicts with environment_id and namespace_key.
      - namespace_key:       (Optional) The map key of an entry in var.module_namespaces whose ID is
                            resolved internally by this module (composition wiring). Conflicts with
                            environment_id and namespace_id.
      - module_provider:     (Optional) Module provider name, e.g. "aws", "azurerm", "google".
      - name:                (Optional) Name of the module, e.g. "rds", "compute", "kubernetes-engine".
      - account_id:          (Optional, DEPRECATED by the upstream provider in favor of namespace_id/
                            namespace_key) The identifier of the account, in the format "acc-<RANDOM STRING>".
                            If set and namespace_id/namespace_key are not, the module is registered
                            globally, available across the whole installation. Still exposed here for
                            full argument coverage of the provider resource.
      - environment_id:      (Optional, DEPRECATED by the upstream provider in favor of namespace_id/
                            namespace_key) The identifier of an environment, in the format "env-<RANDOM STRING>".
                            Conflicts with namespace_id/namespace_key. Still exposed here for full
                            argument coverage of the provider resource.
  EOT
  type = map(object({
    vcs_provider_id = string
    vcs_repo = object({
      identifier = string
      path       = optional(string)
      tag_prefix = optional(string)
    })
    namespace_id    = optional(string)
    namespace_key   = optional(string)
    module_provider = optional(string)
    name            = optional(string)
    account_id      = optional(string)
    environment_id  = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.modules : !(v.namespace_id != null && v.namespace_key != null)
    ])
    error_message = "Each modules entry must not set both namespace_id and namespace_key; set at most one."
  }

  validation {
    condition = alltrue([
      for k, v in var.modules : v.namespace_key == null || contains(keys(var.module_namespaces), v.namespace_key)
    ])
    error_message = "Each modules namespace_key must reference an existing key in var.module_namespaces."
  }

  validation {
    condition = alltrue([
      for k, v in var.modules : !((v.namespace_id != null || v.namespace_key != null) && v.environment_id != null)
    ])
    error_message = "Each modules entry must not set environment_id together with namespace_id/namespace_key; the upstream provider documents namespace_id as conflicting with environment_id."
  }

  validation {
    condition = alltrue([
      for k, v in var.modules : v.vcs_repo.identifier != ""
    ])
    error_message = "Each modules entry's vcs_repo.identifier must be a non-empty string, e.g. \"org/repo\"."
  }
}

variable "module_namespaces" {
  description = <<-EOT
    Map of Scalr Module Namespaces (scalr_module_namespace) to create via the companion
    ./namespace submodule, keyed by a caller-chosen logical name. See ./namespace/variables.tf
    for the full field list. Reference an entry from var.modules by setting that entry's
    namespace_key to this map's key.
  EOT
  type = map(object({
    name         = optional(string)
    environments = optional(set(string))
    is_shared    = optional(bool)
    owners       = optional(set(string))
  }))
  default = {}
}
