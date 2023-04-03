############################################################
# AWS Security Hub Account Variables
############################################################

variable "enable_default_standards" {
  type        = bool
  description = "(Optional) Whether to enable the security standards that Security Hub has designated as automatically enabled including: AWS Foundational Security Best Practices v1.0.0 and CIS AWS Foundations Benchmark v1.2.0. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.enable_default_standards))
    error_message = "The value must be true or false."
  }
}

############################################################
# AWS Security Hub Organization Admin Variables
############################################################

variable "admin_account_id" {
  type        = string
  description = "(Required) The 12-digit identifier of the AWS account designated as the Security Hub administrator account."
  validation {
    condition     = can(regex("^\\d{12}$", var.admin_account_id))
    error_message = "The value must be a 12-digit identifier."
  }
}

############################################################
# AWS Security Hub Organization Admin Variables
############################################################

variable "auto_enable" {
  type        = bool
  description = "(Required) Whether to automatically enable Security Hub for new accounts in the organization. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.auto_enable))
    error_message = "The value must be true or false."
  }
}

variable "auto_enable_standards" {
  type        = string
  description = "(Optional) Whether to automatically enable Security Hub default standards for new member accounts in the organization. By default, this parameter is equal to DEFAULT, and new member accounts are automatically enabled with default Security Hub standards. To opt out of enabling default standards for new member accounts, set this parameter equal to NONE."
  default     = "DEFAULT"
  validation {
    condition     = can(regex("^(DEFAULT|NONE)$", var.auto_enable_standards))
    error_message = "The value must be DEFAULT or NONE."
  }
}
