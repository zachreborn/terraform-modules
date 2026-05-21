###########################
# Budget Configuration
###########################

variable "name" {
  type        = string
  description = "(Required) The name of a budget. Unique within accounts."
  default     = null
  validation {
    condition     = var.name != null && length(var.name) > 0
    error_message = "name must be a non-empty string."
  }
}

variable "account_id" {
  type        = string
  description = "(Optional) The ID of the target account for budget. Defaults to the current account if not specified. Useful when managing budgets for member accounts from a management account."
  default     = null
}

variable "budget_type" {
  type        = string
  description = "(Required) Whether this budget tracks monetary cost or usage. Valid values: COST, USAGE, SAVINGS_PLANS_UTILIZATION, SAVINGS_PLANS_COVERAGE, RI_UTILIZATION, RI_COVERAGE."
  default     = "COST"
  validation {
    condition     = contains(["COST", "USAGE", "SAVINGS_PLANS_UTILIZATION", "SAVINGS_PLANS_COVERAGE", "RI_UTILIZATION", "RI_COVERAGE"], var.budget_type)
    error_message = "budget_type must be one of: COST, USAGE, SAVINGS_PLANS_UTILIZATION, SAVINGS_PLANS_COVERAGE, RI_UTILIZATION, RI_COVERAGE."
  }
}

variable "limit_amount" {
  type        = string
  description = "(Required) The amount of cost or usage being measured for a budget. For COST budgets this is a dollar value (e.g. '100'). For USAGE budgets this is the usage type amount."
  default     = null
  validation {
    condition     = var.limit_amount != null && can(regex("^[0-9]+(\\.[0-9]+)?$", var.limit_amount))
    error_message = "limit_amount must be a numeric string (e.g. '100' or '99.99')."
  }
}

variable "limit_unit" {
  type        = string
  description = "(Required) The unit of measurement used for the budget. For COST budgets use 'USD'. For USAGE budgets use the service-specific unit (e.g. 'GB' for S3 storage)."
  default     = "USD"
  validation {
    condition     = length(var.limit_unit) > 0
    error_message = "limit_unit must be a non-empty string."
  }
}

variable "time_unit" {
  type        = string
  description = "(Required) The length of time until a budget resets the actual and forecasted spend. Valid values: DAILY, MONTHLY, QUARTERLY, ANNUALLY."
  default     = "MONTHLY"
  validation {
    condition     = contains(["DAILY", "MONTHLY", "QUARTERLY", "ANNUALLY"], var.time_unit)
    error_message = "time_unit must be one of: DAILY, MONTHLY, QUARTERLY, ANNUALLY."
  }
}

variable "time_period_start" {
  type        = string
  description = "(Optional) The start of the time period covered by the budget. If not provided, defaults to the beginning of the current month. Format: YYYY-MM-DD_HH:MM."
  default     = null
  validation {
    condition     = var.time_period_start == null ? true : can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}$", var.time_period_start))
    error_message = "time_period_start must be null or in the format YYYY-MM-DD_HH:MM (e.g. '2024-01-01_00:00')."
  }
}

variable "time_period_end" {
  type        = string
  description = "(Optional) The end of the time period covered by the budget. If not provided, defaults to 2087-06-15_00:00. Format: YYYY-MM-DD_HH:MM."
  default     = null
  validation {
    condition     = var.time_period_end == null ? true : can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}:[0-9]{2}$", var.time_period_end))
    error_message = "time_period_end must be null or in the format YYYY-MM-DD_HH:MM (e.g. '2025-12-31_23:59')."
  }
}

###########################
# Notifications
###########################

variable "notification" {
  type = list(object({
    comparison_operator        = string
    notification_type          = string
    threshold                  = number
    threshold_type             = string
    subscriber_email_addresses = optional(list(string), [])
    subscriber_sns_topic_arns  = optional(list(string), [])
  }))
  description = "(Optional) List of notification configurations for the budget. Each entry creates a budget alert. comparison_operator: LESS_THAN, EQUAL_TO, GREATER_THAN. notification_type: ACTUAL or FORECASTED. threshold_type: PERCENTAGE or ABSOLUTE_VALUE."
  default     = []
  validation {
    condition = alltrue([
      for n in var.notification :
      contains(["LESS_THAN", "EQUAL_TO", "GREATER_THAN"], n.comparison_operator)
    ])
    error_message = "Each notification comparison_operator must be one of: LESS_THAN, EQUAL_TO, GREATER_THAN."
  }
  validation {
    condition = alltrue([
      for n in var.notification :
      contains(["ACTUAL", "FORECASTED"], n.notification_type)
    ])
    error_message = "Each notification notification_type must be one of: ACTUAL, FORECASTED."
  }
  validation {
    condition = alltrue([
      for n in var.notification :
      contains(["PERCENTAGE", "ABSOLUTE_VALUE"], n.threshold_type)
    ])
    error_message = "Each notification threshold_type must be one of: PERCENTAGE, ABSOLUTE_VALUE."
  }
}

###########################
# Cost Filters
###########################

variable "cost_filter" {
  type = list(object({
    name   = string
    values = list(string)
  }))
  description = "(Optional) List of cost filters to apply to the budget. Common filter names: LinkedAccount (filter by member account ID), Service (filter by AWS service), Region, TagKeyValue."
  default     = []
}

###########################
# Tagging
###########################

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to the budget resource."
  default     = {}
}
