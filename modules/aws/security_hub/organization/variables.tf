############################################################
# AWS Security Hub CSPM Account Variables
############################################################

variable "enable_default_standards" {
  type        = bool
  description = "(Optional) Whether to enable the security standards that Security Hub CSPM has designated as automatically enabled including: AWS Foundational Security Best Practices v1.0.0 and CIS AWS Foundations Benchmark v1.2.0. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.enable_default_standards))
    error_message = "The value must be true or false."
  }
}

############################################################
# AWS Security Hub CSPM Delegated Administrator Variables
############################################################

variable "admin_account_id" {
  type        = string
  description = "(Required) The 12-digit identifier of the AWS account designated as the Security Hub CSPM delegated administrator account. Per AWS, delegating CSPM to a non-management account also designates it as the delegated administrator for the unified AWS Security Hub."
  validation {
    condition     = can(regex("^\\d{12}$", var.admin_account_id))
    error_message = "The value must be a 12-digit identifier."
  }
}

############################################################
# AWS Security Hub CSPM Organization Configuration Variables
############################################################

variable "auto_enable" {
  type        = bool
  description = "(Optional) Whether to automatically enable Security Hub CSPM for new accounts in the organization. Only applies to LOCAL configuration; when configuration_type is CENTRAL this is forced to false. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.auto_enable))
    error_message = "The value must be true or false."
  }
}

variable "auto_enable_standards" {
  type        = string
  description = "(Optional) Whether to automatically enable Security Hub CSPM default standards for new member accounts in the organization. Valid values are DEFAULT and NONE. Only applies to LOCAL configuration; when configuration_type is CENTRAL this is forced to NONE. Defaults to DEFAULT."
  default     = "DEFAULT"
  validation {
    condition     = can(regex("^(DEFAULT|NONE)$", var.auto_enable_standards))
    error_message = "The value must be DEFAULT or NONE."
  }
}

variable "configuration_type" {
  type        = string
  description = "(Optional) Whether the organization uses LOCAL or CENTRAL configuration. LOCAL (default) preserves the historical behavior where each account/Region is configured independently and auto_enable applies. CENTRAL enables configuration policies (see configuration_policies), requires a finding aggregator, and forces auto_enable to false and auto_enable_standards to NONE. Valid values: LOCAL, CENTRAL."
  default     = "LOCAL"
  validation {
    condition     = contains(["LOCAL", "CENTRAL"], var.configuration_type)
    error_message = "The value must be LOCAL or CENTRAL."
  }
}

variable "configuration_policies" {
  type = map(object({
    description                  = optional(string)
    service_enabled              = optional(bool, true)
    enabled_standard_arns        = optional(list(string), [])
    enabled_control_identifiers  = optional(list(string), [])
    disabled_control_identifiers = optional(list(string), [])
    target_ids                   = optional(list(string), [])
  }))
  description = "(Optional) Map of Security Hub CSPM central configuration policies keyed by policy name. Only used when configuration_type is CENTRAL. Per policy: service_enabled toggles Security Hub CSPM on/off for associated targets; enabled_standard_arns lists the standard ARNs to enable; provide either enabled_control_identifiers or disabled_control_identifiers (mutually exclusive - a non-empty enabled_control_identifiers takes precedence); target_ids is the list of organization root, OU, or account IDs to associate with the policy. Defaults to an empty map (no policies)."
  default     = {}
}

############################################################
# AWS Security Hub CSPM Finding Aggregator Variables
############################################################

variable "linking_mode" {
  type        = string
  description = "(Optional) Indicates whether to aggregate findings from all of the available Regions or from a specified list. The options are ALL_REGIONS, ALL_REGIONS_EXCEPT_SPECIFIED or SPECIFIED_REGIONS. When ALL_REGIONS or ALL_REGIONS_EXCEPT_SPECIFIED are used, Security Hub CSPM will automatically aggregate findings from new Regions as Security Hub supports them and you opt into them."
  default     = "ALL_REGIONS"
  validation {
    condition     = can(regex("^(ALL_REGIONS|ALL_REGIONS_EXCEPT_SPECIFIED|SPECIFIED_REGIONS)$", var.linking_mode))
    error_message = "The value must be ALL_REGIONS, ALL_REGIONS_EXCEPT_SPECIFIED or SPECIFIED_REGIONS."
  }
}

variable "specified_regions" {
  type        = list(string)
  description = "(Optional) List of regions to include or exclude (required if linking_mode is set to ALL_REGIONS_EXCEPT_SPECIFIED or SPECIFIED_REGIONS)"
  default     = null
}
