###########################
# Scalr Tag
###########################

variable "tags" {
  description = <<-EOT
    (Required) Map of Scalr tags to create, keyed by a caller-chosen logical name (e.g. "network").
    Fields:
      - name:       (Optional) The literal tag name in Scalr. Defaults to the entry's map key when unset.
      - account_id: (Optional) ID of the account the tag belongs to, in the format `acc-<RANDOM STRING>`.
                    Defaults to null, in which case the provider resolves the account from its own
                    configuration (e.g. the ACCOUNT_ID it was configured with).
  EOT
  type = map(object({
    name       = optional(string)
    account_id = optional(string)
  }))
}
