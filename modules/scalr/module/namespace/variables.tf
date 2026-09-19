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
    # Note: intentionally not calling coalesce(v.name, k) here -- coalesce() raises a hard
    # evaluation error ("no non-null, non-empty-string arguments") rather than returning
    # false when every argument is null/empty, which would crash validation entirely for an
    # empty key + omitted name instead of surfacing the error_message below. This ternary
    # reproduces coalesce()'s "first non-null, non-empty-string value" semantics without
    # ever calling it on an all-invalid input.
    condition = alltrue([
      for k, v in var.module_namespaces : (v.name != null && v.name != "" ? v.name : k) != ""
    ])
    error_message = "Each module_namespaces entry must resolve to a non-empty name (set name explicitly or use a non-empty map key)."
  }
}
