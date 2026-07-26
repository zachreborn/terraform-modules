###########################
# Resource Variables
###########################
variable "module_namespaces" {
  description = <<-EOT
    Map of Scalr Module Namespaces (scalr_module_namespace) to create, keyed by a caller-chosen
    logical name. Fields:
      - name:         (Optional) Name of the module namespace. Defaults to the entry's map key.
      - environments: (Optional) Set of environment IDs associated with the module namespace.
      - is_shared:    (Optional) Whether the module namespace is shared.
      - owners:       (Optional) Set of team IDs that own the module namespace.
  EOT
  type = map(object({
    name         = optional(string)
    environments = optional(set(string))
    is_shared    = optional(bool)
    owners       = optional(set(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.module_namespaces : coalesce(v.name, k) != ""
    ])
    error_message = "Each module_namespaces entry must resolve to a non-empty name (set name explicitly or use a non-empty map key)."
  }
}
