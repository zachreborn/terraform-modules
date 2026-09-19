###########################
# Resource Variables
###########################
variable "teams" {
  description = <<-EOT
    (Optional) Map of Scalr IAM teams to create, keyed by a caller-chosen logical name (e.g. "dev").
    Each entry:
      - name:                  (Optional) A name of the team. Defaults to the entry's map key when
                                unset.
      - description:           (Optional) A verbose description of the team.
      - users:                 (Optional) Set of user identifiers (format 'user-') to add to the
                                team. Should not be used when the account's identity provider is not
                                of type 'scalr', since team membership is then managed externally.
      - account_id:            (Optional) ID of the account, in the format 'acc-'. Falls back to
                                var.account_id when unset.
      - identity_provider_id:  (Optional, DEPRECATED upstream) An identifier of the login identity
                                provider, in the format 'idp-'. Kept here for full attribute coverage
                                per AGENTS.md, but the Scalr provider deprecates this attribute --
                                new configurations should generally leave it unset.
  EOT
  type = map(object({
    name                 = optional(string)
    description          = optional(string)
    users                = optional(set(string))
    account_id           = optional(string)
    identity_provider_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.teams : v != null
    ])
    error_message = "Each teams entry must be an object; bare/null entries are not supported."
  }
}

###########################
# General Variables
###########################
variable "account_id" {
  description = "(Optional) Default ID of the account, in the format 'acc-', used for any teams entry that does not set its own account_id."
  type        = string
  default     = null
}
