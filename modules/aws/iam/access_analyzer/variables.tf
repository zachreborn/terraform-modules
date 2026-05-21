###########################
# Access Analyzer Variables
###########################
variable "analyzer_name" {
  type        = string
  description = "(Required) Name of the Access Analyzer. Used as a fixed name to support import capability."
  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{1,255}$", var.analyzer_name))
    error_message = "The analyzer_name must be 1-255 characters and contain only alphanumeric characters, underscores, hyphens, and periods."
  }
}

variable "analyzer_type" {
  type        = string
  description = "(Optional) Type of analyzer to create. Valid values: ACCOUNT, ACCOUNT_UNUSED_ACCESS, ORGANIZATION, ORGANIZATION_UNUSED_ACCESS. Defaults to ORGANIZATION."
  default     = "ORGANIZATION"
  validation {
    condition     = contains(["ACCOUNT", "ACCOUNT_UNUSED_ACCESS", "ORGANIZATION", "ORGANIZATION_UNUSED_ACCESS"], var.analyzer_type)
    error_message = "The analyzer_type must be one of: ACCOUNT, ACCOUNT_UNUSED_ACCESS, ORGANIZATION, ORGANIZATION_UNUSED_ACCESS."
  }
}

variable "archive_rules" {
  type = list(object({
    rule_name = string
    filter = list(object({
      criteria = string
      eq       = optional(list(string), null)
      neq      = optional(list(string), null)
      contains = optional(list(string), null)
      exists   = optional(bool, null)
    }))
  }))
  description = "(Optional) List of archive rules to create on the analyzer. Each rule requires a rule_name and one or more filter blocks. Each filter specifies a criteria property and exactly one of: eq (exact match list), neq (not-equal list), contains (substring match list), or exists (bool)."
  default     = []
}

###########################
# Organization Variables
###########################
variable "admin_account_id" {
  type        = string
  description = "(Required) The AWS account ID of the security/delegated admin account where the Access Analyzer will be created."
  validation {
    condition     = can(regex("^\\d{12}$", var.admin_account_id))
    error_message = "The admin_account_id must be a 12-digit AWS account ID."
  }
}

variable "register_delegated_admin" {
  type        = bool
  description = "(Optional) Whether to register the admin_account_id as a delegated administrator for access-analyzer.amazonaws.com. Set to false if the account is already registered. Defaults to true."
  default     = true
}

###########################
# General Variables
###########################
variable "tags" {
  type        = map(string)
  description = "(Optional) Map of tags to assign to the Access Analyzer."
  default     = {}
}
