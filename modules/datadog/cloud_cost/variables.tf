###########################
# Resource Variables
###########################

variable "config" {
  description = <<-EOT
    Single aggregated configuration object for all Datadog Cloud Cost Management resources.
    Intended to be populated from one YAML file via `config = yamldecode(file("cloud_cost.yaml"))`.
    Each top-level key maps to one of the underlying submodules:
      - aws_cur_configs  -> AWS Cost and Usage Report configurations
      - ccm_configs      -> Cloud Cost Management configs linked to AWS integrations
      - budgets          -> Cost budgets
      - allocation_rules -> Custom allocation rules
    Rule evaluation order is controlled by enable_rule_order + rule_order (a list of logical
    rule names that are resolved to IDs internally).
  EOT
  type = object({
    # AWS CUR configurations -> datadog_aws_cur_config
    aws_cur_configs = optional(map(object({
      account_id    = string
      bucket_name   = string
      report_name   = string
      report_prefix = string
      bucket_region = optional(string, null)
      account_filters = optional(object({
        include_new_accounts = optional(bool, null)
        excluded_accounts    = optional(list(string), null)
        included_accounts    = optional(list(string), null)
      }), null)
    })), {})

    # Cloud Cost Management configs -> datadog_integration_aws_account_ccm_config
    ccm_configs = optional(map(object({
      aws_account_config_id = string
      ccm_config = optional(object({
        data_export_configs = optional(list(object({
          bucket_name   = optional(string, null)
          bucket_region = optional(string, null)
          report_name   = optional(string, null)
          report_prefix = optional(string, null)
          report_type   = optional(string, null)
        })), null)
      }), null)
    })), {})

    # Cost budgets -> datadog_cost_budget
    budgets = optional(map(object({
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
    })), {})

    # Custom allocation rules -> datadog_custom_allocation_rule
    allocation_rules = optional(map(object({
      rule_name     = string
      enabled       = bool
      providernames = list(string)
      costs_to_allocate = optional(list(object({
        condition = optional(string, null)
        tag       = optional(string, null)
        value     = optional(string, null)
        values    = optional(list(string), null)
      })), [])
      strategy = optional(object({
        allocated_by_tag_keys        = optional(list(string), null)
        evaluate_grouped_by_tag_keys = optional(list(string), null)
        granularity                  = optional(string, null)
        method                       = optional(string, null)
        allocated_by = optional(list(object({
          percentage = optional(number, null)
          allocated_tags = optional(list(object({
            key   = optional(string, null)
            value = optional(string, null)
          })), [])
        })), [])
        allocated_by_filters = optional(list(object({
          condition = optional(string, null)
          tag       = optional(string, null)
          value     = optional(string, null)
          values    = optional(list(string), null)
        })), [])
        based_on_costs = optional(list(object({
          condition = optional(string, null)
          tag       = optional(string, null)
          value     = optional(string, null)
          values    = optional(list(string), null)
        })), [])
        based_on_timeseries = optional(bool, null)
        evaluate_grouped_by_filters = optional(list(object({
          condition = optional(string, null)
          tag       = optional(string, null)
          value     = optional(string, null)
          values    = optional(list(string), null)
        })), [])
      }), null)
    })), {})

    # Custom allocation rule evaluation order
    enable_rule_order             = optional(bool, false)
    rule_order                    = optional(list(string), [])
    override_ui_defined_resources = optional(bool, false)
  })
  default = {}
}
