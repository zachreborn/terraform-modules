###########################
# Resource Variables
###########################
variable "tokens" {
  description = <<-EOT
    (Optional) Map of Scalr Service Account tokens to create, keyed by a caller-chosen logical name
    (e.g. "default"). Each entry must set exactly one of:
      - service_account_id:  A literal Scalr Service Account ID (format 'sa-').
      - service_account_key: A key into var.service_account_ids (e.g. the `ids` output of
                              modules/scalr/iam/service_account) identifying the service account this
                              token should be issued for.
    Other fields:
      - description: (Optional) Description of the token.
      - expires_in:  (Optional) Number of minutes until the token expires.
      - name:        (Optional) Name of the token.
  EOT
  type = map(object({
    service_account_id  = optional(string)
    service_account_key = optional(string)
    description         = optional(string)
    expires_in          = optional(number)
    name                = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.tokens : v != null
    ])
    error_message = "Each tokens entry must be an object; bare/null entries are not supported."
  }

  validation {
    condition = alltrue([
      for k, v in var.tokens : v != null ? (v.service_account_id != null) != (v.service_account_key != null) : true
    ])
    error_message = "Each tokens entry must set exactly one of service_account_id or service_account_key."
  }
}

variable "service_account_ids" {
  description = "(Optional) Map of Scalr Service Account IDs keyed by logical name, e.g. the `ids` output of modules/scalr/iam/service_account. Referenced by each tokens entry's service_account_key."
  type        = map(string)
  default     = {}
}
