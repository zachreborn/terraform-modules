###########################
# Resource Variables
###########################
variable "roles" {
  description = <<-EOT
    (Optional) Map of Scalr IAM roles to create, keyed by a caller-chosen logical name (e.g.
    "writer"). Each entry:
      - name:        (Optional) Name of the role. Defaults to the entry's map key when unset.
      - permissions: (Required) Set of permission names to grant (e.g. "*:update", "*:delete",
                     "*:create"). Must be non-empty.
      - account_id:  (Optional) ID of the account, in the format 'acc-'. Deprecated upstream by the
                     Scalr provider -- kept here for full attribute coverage per AGENTS.md, but new
                     configurations should rely on the provider's default account resolution and
                     leave this unset (falls back to var.account_id).
      - description: (Optional) Verbose description of the role.
  EOT
  type = map(object({
    name        = optional(string)
    permissions = set(string)
    account_id  = optional(string)
    description = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.roles : v != null
    ])
    error_message = "Each roles entry must be an object; bare/null entries are not supported since there is no reasonable default for permissions."
  }

  validation {
    condition = alltrue([
      for k, v in var.roles : v != null ? length(v.permissions) > 0 : true
    ])
    error_message = "Each roles entry must set a non-empty permissions set."
  }
}

###########################
# General Variables
###########################
variable "account_id" {
  description = <<-EOT
    (Optional) Default ID of the account, in the format 'acc-', used for any roles entry that does
    not set its own account_id. This attribute is deprecated upstream by the Scalr provider -- new
    configurations should generally leave both this and each entry's account_id unset so the
    provider resolves the account from the caller's credentials.
  EOT
  type        = string
  default     = null
}
