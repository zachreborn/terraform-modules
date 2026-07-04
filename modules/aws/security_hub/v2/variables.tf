###########################################################
# Security Hub V2 Finding Aggregator Variables
###########################################################

variable "enable_finding_aggregation" {
  type        = bool
  description = "(Optional) Whether to create a Security Hub V2 cross-Region finding aggregator. Must be true to use automation_rules. Defaults to true."
  default     = true
}

variable "region_linking_mode" {
  type        = string
  description = "(Optional) Determines how Regions are linked to the aggregator. Valid values: ALL_REGIONS, ALL_REGIONS_EXCEPT_SPECIFIED, SPECIFIED_REGIONS. Only used when enable_finding_aggregation is true. Defaults to ALL_REGIONS."
  default     = "ALL_REGIONS"
  validation {
    condition     = contains(["ALL_REGIONS", "ALL_REGIONS_EXCEPT_SPECIFIED", "SPECIFIED_REGIONS"], var.region_linking_mode)
    error_message = "The value must be ALL_REGIONS, ALL_REGIONS_EXCEPT_SPECIFIED, or SPECIFIED_REGIONS."
  }
}

variable "linked_regions" {
  type        = list(string)
  description = "(Optional) List of Regions linked to the aggregation Region. Required when region_linking_mode is SPECIFIED_REGIONS or ALL_REGIONS_EXCEPT_SPECIFIED; otherwise leave null. Defaults to null."
  default     = null
}

###########################################################
# Security Hub V2 Automation Rule Variables
###########################################################

variable "automation_rules" {
  type = map(object({
    description                = string
    rule_order                 = number
    rule_status                = optional(string, "ENABLED")
    ocsf_finding_criteria_json = string
    action_type                = optional(string, "FINDING_FIELDS_UPDATE")
    finding_fields_update = optional(object({
      comment     = optional(string)
      severity_id = optional(number)
      status_id   = optional(number)
    }))
    external_integration_connector_arn = optional(string)
  }))
  description = "(Optional) Map of Security Hub V2 automation rules keyed by rule name. Requires enable_finding_aggregation = true. Per rule: rule_order sets priority (lower is higher priority); rule_status is ENABLED or DISABLED; ocsf_finding_criteria_json is the JSON-encoded OCSF finding criteria; action_type is FINDING_FIELDS_UPDATE or EXTERNAL_INTEGRATION; supply finding_fields_update for FINDING_FIELDS_UPDATE actions, or external_integration_connector_arn for EXTERNAL_INTEGRATION actions. Defaults to an empty map (no rules)."
  default     = {}
}

###########################################################
# General Variables
###########################################################

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to the Security Hub V2 resources created by this module (account, aggregator, and automation rules)."
  default     = {}
}
