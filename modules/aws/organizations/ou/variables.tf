variable "organizational_units" {
  description = <<-EOT
    (Required) Map of Organizational Units to create, keyed by a caller-chosen logical name (e.g. "workloads").
    A bare entry (e.g. `workloads:` with no value in YAML, which decodes to null) is a valid value for this
    map's element type, but this module's own validation always rejects it, since a null entry has neither
    parent_id nor parent_key set (see below). Bare entries are only useful as an authoring convenience for a
    caller (such as the modules/aws/organizations composed module) that resolves each entry into a concrete
    object -- typically injecting a default parent_id -- before passing the map to this module; by the time
    this module validates organizational_units, no entry may still be null.
    Each entry must set exactly one of:
      - parent_id:  A literal parent Root ID (e.g. "r-abcd") or an externally-managed OU ID. Use this for
                    top-level entries whose parent is not itself created by this module call.
      - parent_key: The map key of another entry in this same variable that is this OU's parent. Use this
                    for OUs nested under an OU also being created by this module call (e.g. an entry named
                    "prod" can set parent_key = "workloads" to nest under the "workloads" entry).
    Nesting via parent_key is supported up to 4 levels deep (i.e. an entry's parent_key chain may pass
    through at most 3 other entries before reaching an entry that sets a literal parent_id). AWS
    Organizations itself supports up to 5 levels of OUs below the root; entries that would resolve deeper
    than the 4 levels supported here will fail the precondition on the module's `ids` output.
    Fields:
      - name:       (Optional) The name of the Organizational Unit. Defaults to the entry's map key when unset.
      - parent_id:  (Optional) Literal parent Root or OU ID. Conflicts with parent_key.
      - parent_key: (Optional) Key of another entry in this map that is this OU's parent. Conflicts with parent_id.
      - tags:       (Optional) Additional tags for this OU, merged with var.tags.
  EOT
  type = map(object({
    name       = optional(string)
    parent_id  = optional(string)
    parent_key = optional(string)
    tags       = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.organizational_units : v != null ? (v.parent_id != null) != (v.parent_key != null) : false
    ])
    error_message = "Each organizational_units entry must set exactly one of parent_id or parent_key; a bare/null entry has neither. Set parent_id or parent_key explicitly, or use the modules/aws/organizations composed module (with organization set), which resolves bare top-level entries to the managed Organization's root before this validation runs."
  }

  validation {
    condition = alltrue([
      for k, v in var.organizational_units : v == null || v.parent_key == null || contains(keys(var.organizational_units), v.parent_key)
    ])
    error_message = "Each organizational_units parent_key must reference an existing key in var.organizational_units."
  }

  validation {
    condition = alltrue([
      for k, v in var.organizational_units : v == null || v.parent_key != k
    ])
    error_message = "An organizational_units entry cannot set its own key as parent_key."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to every Organizational Unit, merged with each entry's optional per-OU tags."
  default = {
    terraform = "true"
  }
}
