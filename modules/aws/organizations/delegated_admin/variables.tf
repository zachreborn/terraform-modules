############################################################
# AWS Organization Delegated Administrator
############################################################

variable "delegated_admins" {
  description = <<-EOT
    (Optional) Map of delegated administrator configurations keyed by a caller-supplied static logical
    name (e.g. "backups", "security"). The map key must be known at plan time — a string literal or
    local value, never a resource attribute such as an AWS account ID — so the resource for_each key
    remains resolvable even when account_id is an apply-time-unknown value.

    Each entry has:
      - account_id : The AWS account ID to register as a delegated administrator. May be an
                     apply-time value such as module.organizations.account_ids["backups"]; it is
                     passed only as a resource argument value, never used as a for_each key.
      - services   : Non-empty list of service principal names to associate with the account
                     (e.g. ["backup.amazonaws.com", "config.amazonaws.com"]).

    Example:
      delegated_admins = {
        backups = {
          account_id = module.organizations.account_ids["backups"]
          services   = ["backup.amazonaws.com"]
        }
        security = {
          account_id = "123456789012"
          services   = ["guardduty.amazonaws.com", "securityhub.amazonaws.com"]
        }
      }
  EOT
  type = map(object({
    account_id = string
    services   = list(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, entry in var.delegated_admins : length(entry.services) > 0
    ])
    error_message = "Each delegated_admins entry must have at least one service principal in its 'services' list. Check entries with an empty services list."
  }
}

############################################################
# General Variables
############################################################
