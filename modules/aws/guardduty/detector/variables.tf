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
