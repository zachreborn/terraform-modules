###########################
# GuardDuty Detector Variables
###########################
variable "enable" {
  type        = bool
  description = "(Optional) Enable monitoring and feedback reporting. Setting to false is equivalent to 'suspending' GuardDuty. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.enable))
    error_message = "The value of enable must be either true or false."
  }
}

variable "finding_publishing_frequency" {
  type        = string
  description = "(Optional) Specifies the frequency of notifications sent for subsequent finding occurrences. If the detector is a GuardDuty member account, the value is determined by the GuardDuty primary account and cannot be modified, otherwise defaults to SIX_HOURS. For standalone and GuardDuty primary accounts, it must be configured in Terraform to enable drift detection. Valid values for standalone and primary accounts: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS. See AWS Documentation for more information."
  default     = "SIX_HOURS"
  validation {
    condition     = can(regex("^(FIFTEEN_MINUTES|ONE_HOUR|SIX_HOURS)$", var.finding_publishing_frequency))
    error_message = "The value of finding_publishing_frequency must be either FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

###########################
# GuardDuty Organization Variables
###########################
variable "admin_account_id" {
  type        = string
  description = "(Optional) The AWS account ID for the GuardDuty delegated administrator account. This must be an existing account in the organization."
  default     = null
  validation {
    condition     = var.admin_account_id == null ? true : can(regex("^\\d{12}$", var.admin_account_id))
    error_message = "The value of admin_account_id must be a 12-digit AWS account ID or null."
  }
}

variable "auto_enable_auto_enable_organization_members" {
  type        = string
  description = "(Optional) Indicates the auto-enablement configuration of GuardDuty for the member accounts in the organization. Valid values are ALL, NEW, NONE. Defaults to ALL."
  default     = "ALL"
  validation {
    condition     = can(regex("^(ALL|NEW|NONE)$", var.auto_enable_auto_enable_organization_members))
    error_message = "The value of auto_enable_auto_enable_organization_members must be either ALL, NEW, or NONE."
  }
}

variable "s3_logs_enable" {
  type        = bool
  description = "(Optional) When this setting is enabled, GuardDuty will automatically enable S3 data sources for new accounts in the organization. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.s3_logs_enable))
    error_message = "The value of s3_logs_enable must be either true or false."
  }
}

###########################
# General Variables
###########################
