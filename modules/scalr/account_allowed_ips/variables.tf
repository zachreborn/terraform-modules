###########################
# Resource Variables
###########################
variable "account_allowed_ips" {
  description = <<-EOT
    Map of Scalr account allowed-IP lists keyed by a caller-supplied logical name. Each entry
    manages one `scalr_account_allowed_ips` resource, restricting which source IPs/CIDRs may
    access the account.

    WARNING: if you omit your own current IP address (or CIDR range) from `allowed_ips`, you
    may immediately lock yourself (and everyone else) out of the account. Recovering from a
    lockout requires the account owner to open a Scalr support ticket
    (https://support.scalr.com) — there is no self-service recovery path. See the README's
    "Notes / Design Decisions" section before using this module.

    Fields:
      - account_id:  (Optional) ID of the account, in the format "acc-<RANDOM STRING>". Falls
                     back to var.account_id when unset.
      - allowed_ips: (Required) Non-empty list of allowed IPs or CIDRs.

    Example:
      account_allowed_ips = {
        default = {
          account_id  = "acc-xxxxxxxxxx"
          allowed_ips = [var.caller_ip_address, "<office-network-cidr>"]
        }
      }
  EOT
  type = map(object({
    account_id  = optional(string)
    allowed_ips = list(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.account_allowed_ips : length(value.allowed_ips) > 0
    ])
    error_message = "Each account_allowed_ips entry's allowed_ips list must be non-empty. An empty list risks locking every caller out of the account; see the README's lockout warning before proceeding."
  }
}

###########################
# General Variables
###########################
variable "account_id" {
  description = "(Optional) Default Scalr account ID, in the format \"acc-<RANDOM STRING>\", used for any account_allowed_ips entry that does not set its own account_id."
  type        = string
  default     = null
}
