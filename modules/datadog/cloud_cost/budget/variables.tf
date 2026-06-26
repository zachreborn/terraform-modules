###########################
# Resource Variables
###########################

variable "budgets" {
  description = "Map of cost budgets to create. Each key is a logical name for the budget. Prefer budget_lines over entries (entries is deprecated)."
  type = map(object({
    name          = string
    metrics_query = string
    start_month   = number
    end_month     = number
    budget_lines = optional(list(object({
      amounts = map(number)
      tag_filters = optional(list(object({
        tag_key   = string
        tag_value = string
      })), [])
      parent_tag_filters = optional(list(object({
        tag_key   = string
        tag_value = string
      })), [])
      child_tag_filters = optional(list(object({
        tag_key   = string
        tag_value = string
      })), [])
    })), [])
    entries = optional(list(object({
      month  = number
      amount = number
      tag_filters = optional(list(object({
        tag_key   = string
        tag_value = string
      })), [])
    })), [])
  }))
}
