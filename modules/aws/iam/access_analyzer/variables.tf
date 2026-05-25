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
  description = "(Optional) Type of analyzer to create. Valid values: ACCOUNT, ACCOUNT_INTERNAL_ACCESS, ACCOUNT_UNUSED_ACCESS, ORGANIZATION, ORGANIZATION_INTERNAL_ACCESS, ORGANIZATION_UNUSED_ACCESS. Defaults to ORGANIZATION."
  default     = "ORGANIZATION"
  validation {
    condition     = contains(["ACCOUNT", "ACCOUNT_INTERNAL_ACCESS", "ACCOUNT_UNUSED_ACCESS", "ORGANIZATION", "ORGANIZATION_INTERNAL_ACCESS", "ORGANIZATION_UNUSED_ACCESS"], var.analyzer_type)
    error_message = "The analyzer_type must be one of: ACCOUNT, ACCOUNT_INTERNAL_ACCESS, ACCOUNT_UNUSED_ACCESS, ORGANIZATION, ORGANIZATION_INTERNAL_ACCESS, ORGANIZATION_UNUSED_ACCESS."
  }
}

variable "archive_rules" {
  type = map(object({
    filter = list(object({
      criteria = string
      eq       = optional(list(string), null)
      neq      = optional(list(string), null)
      contains = optional(list(string), null)
      exists   = optional(bool, null)
    }))
  }))
  description = "(Optional) Map of archive rules to create on the analyzer, keyed by rule name. Each rule requires one or more filter blocks. Each filter specifies a criteria property and exactly one of: eq (exact match list), neq (not-equal list), contains (substring match list), or exists (bool)."
  default     = {}
}

###########################
# Configuration Variables
###########################
variable "unused_access_age" {
  type        = number
  description = "(Optional) Number of days for which to generate findings for unused access. Only applicable for ACCOUNT_UNUSED_ACCESS and ORGANIZATION_UNUSED_ACCESS analyzer types. If null, the AWS default is used."
  default     = null
  validation {
    condition     = var.unused_access_age == null ? true : var.unused_access_age > 0
    error_message = "unused_access_age must be a positive integer."
  }
}

variable "unused_access_analysis_rule_exclusions" {
  type = list(object({
    account_ids   = optional(list(string), null)
    resource_tags = optional(list(map(string)), null)
  }))
  description = "(Optional) List of exclusion rules for the unused access analyzer. Entities matching any exclusion will not generate findings. Each exclusion may specify account_ids (list of AWS account IDs to exclude) and/or resource_tags (list of tag key-value maps to exclude). Only applicable for ACCOUNT_UNUSED_ACCESS and ORGANIZATION_UNUSED_ACCESS analyzer types."
  default     = []
}

variable "internal_access_analysis_rule_inclusions" {
  type = list(object({
    account_ids    = optional(list(string), null)
    resource_arns  = optional(list(string), null)
    resource_types = optional(list(string), null)
  }))
  description = "(Optional) List of inclusion rules for the internal access analyzer. Only resources matching an inclusion rule will generate findings. Each inclusion may specify account_ids, resource_arns, and/or resource_types. Only applicable for ACCOUNT_INTERNAL_ACCESS and ORGANIZATION_INTERNAL_ACCESS analyzer types."
  default     = []
}

###########################
# Organization Variables
###########################
variable "admin_account_id" {
  type        = string
  description = "(Optional) The AWS account ID of the security/delegated admin account. Required when register_delegated_admin is true."
  default     = null
  validation {
    condition     = var.admin_account_id == null ? true : can(regex("^\\d{12}$", var.admin_account_id))
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
