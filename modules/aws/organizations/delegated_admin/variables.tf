############################################################
# AWS Organization Delegated Administrator
############################################################

variable "delegated_admins" {
  description = <<-EOT
    (Optional) Map of delegated administrator configurations keyed by a caller-supplied static logical
    name (e.g. "backups", "security"). The map key must be known at plan time — a string literal or
    local value, never a resource attribute such as an AWS account ID — so the resource for_each key
    remains resolvable even when the resolved account ID is an apply-time-unknown value.

    Each entry must set exactly one of:
      - account_id:  A literal AWS account ID to register as a delegated administrator. May be an
                     apply-time value such as module.organizations.account_ids["backups"]; it is
                     passed only as a resource argument value, never used as a for_each key.
      - account_key: A key into var.account_ids (e.g. the `ids` output of
                     modules/aws/organizations/account), letting a caller resolve the account ID from a
                     sibling map instead of hard-coding or wiring it in from an outer module block.
    Fields:
      - account_id:  (Optional) Literal AWS account ID. Conflicts with account_key.
      - account_key: (Optional) Key into var.account_ids. Conflicts with account_id.
      - services:    (Required) Non-empty list of service principal names to associate with the account
                     (e.g. ["backup.amazonaws.com", "config.amazonaws.com"]).

    Example:
      delegated_admins = {
        backups = {
          account_id = module.organizations.account_ids["backups"]
          services   = ["backup.amazonaws.com"]
        }
        security = {
          account_key = "security"
          services    = ["guardduty.amazonaws.com", "securityhub.amazonaws.com"]
        }
      }
  EOT
  type = map(object({
    account_id  = optional(string)
    account_key = optional(string)
    services    = list(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, entry in var.delegated_admins : (entry.account_id != null) != (entry.account_key != null)
    ])
    error_message = "Each delegated_admins entry must set exactly one of account_id or account_key."
  }

  validation {
    condition = alltrue([
      for key, entry in var.delegated_admins : length(entry.services) > 0
    ])
    error_message = "Each delegated_admins entry must have at least one service principal in its 'services' list. Check entries with an empty services list."
  }
}

variable "account_ids" {
  description = "(Optional) Map of AWS account IDs keyed by logical name, e.g. the `ids` output of modules/aws/organizations/account. Referenced by each delegated_admins entry's account_key."
  type        = map(string)
  default     = {}
}

############################################################
# General Variables
############################################################
