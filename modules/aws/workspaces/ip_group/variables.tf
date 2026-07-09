variable "ip_groups" {
  description = <<-EOT
    (Optional) Map of WorkSpaces IP access control groups to create, keyed by a caller-chosen logical name.
    Fields:
      - name:        (Optional) Name of the IP group. Defaults to the entry's map key when unset.
      - description: (Optional) Description of the IP group.
      - rules:       (Optional) List of CIDR rules for this group. Each rule sets source (Required, CIDR
                     notation, e.g. "10.0.0.0/16") and an optional description. Defaults to [].
      - tags:        (Optional) Additional tags for this IP group, merged with var.tags.
  EOT
  type = map(object({
    name        = optional(string)
    description = optional(string)
    rules = optional(list(object({
      source      = string
      description = optional(string)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to every IP group, merged with each entry's optional per-group tags."
  default     = {}
}
