###########################
# Scalr Var Set
###########################

variable "var_sets" {
  description = <<-EOT
    (Optional) Map of Scalr variable sets (`scalr_var_set`) to create, keyed by a caller-chosen logical name
    (e.g. "shared_defaults"). This key can also be referenced by var.workspace_links entries via var_set_key.
    Fields:
      - name:         (Optional) Name of the variable set. Defaults to the entry's map key when unset.
      - description:  (Optional) Description of the variable set.
      - environments: (Optional) Set of environment IDs this variable set is shared to. Use ["*"] to share with
                       all environments.
      - owners:       (Optional) Set of team IDs this variable set belongs to.
  EOT
  type = map(object({
    name         = optional(string)
    description  = optional(string)
    environments = optional(set(string))
    owners       = optional(set(string))
  }))
  default = {}
}

###########################
# Scalr Workspace Var Set Links
###########################

variable "workspace_links" {
  description = <<-EOT
    (Optional) Map of workspace <-> variable set links to create via the companion ./workspace_link submodule,
    keyed by a caller-chosen logical name. Each entry must set exactly one of:
      - var_set_id:  A literal variable set ID, in the format `varset-<RANDOM STRING>` (e.g. for a variable set
                     managed outside this module call).
      - var_set_key: A key into var.var_sets, resolving to the ID of a variable set created by this same module
                     call. An unknown key fails naturally when OpenTofu/Terraform tries to index
                     scalr_var_set.this by that key.
    Fields:
      - workspace_id: (Required) ID of the workspace, in the format `ws-<RANDOM STRING>`.
      - var_set_id:   (Optional) Literal variable set ID. Conflicts with var_set_key.
      - var_set_key:  (Optional) Key into var.var_sets. Conflicts with var_set_id.
  EOT
  type = map(object({
    workspace_id = string
    var_set_id   = optional(string)
    var_set_key  = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.workspace_links : (v.var_set_id != null) != (v.var_set_key != null)
    ])
    error_message = "Each workspace_links entry must set exactly one of var_set_id or var_set_key."
  }
}
