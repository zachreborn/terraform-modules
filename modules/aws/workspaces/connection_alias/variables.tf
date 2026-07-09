variable "connection_aliases" {
  description = <<-EOT
    (Optional) Map of WorkSpaces connection aliases (cross-Region redirection FQDNs) to create, keyed by a
    caller-chosen logical name.
    Fields:
      - connection_string: (Required) Fully qualified domain name for the connection alias, e.g.
                            "workspaces.example.com".
      - tags:              (Optional) Additional tags for this connection alias, merged with var.tags.
  EOT
  type = map(object({
    connection_string = string
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to every connection alias, merged with each entry's optional per-alias tags."
  default     = {}
}
