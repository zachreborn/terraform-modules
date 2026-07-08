###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Locals
###########################

###########################
# Module Configuration
###########################
resource "datadog_custom_allocation_rule" "this" {
  for_each = var.allocation_rules

  rule_name     = each.value.rule_name
  enabled       = each.value.enabled
  providernames = each.value.providernames

  dynamic "costs_to_allocate" {
    for_each = each.value.costs_to_allocate != null ? each.value.costs_to_allocate : []
    content {
      condition = costs_to_allocate.value.condition
      tag       = costs_to_allocate.value.tag
      value     = costs_to_allocate.value.value
      values    = costs_to_allocate.value.values
    }
  }

  dynamic "strategy" {
    for_each = each.value.strategy != null ? [each.value.strategy] : []
    content {
      allocated_by_tag_keys        = strategy.value.allocated_by_tag_keys
      evaluate_grouped_by_tag_keys = strategy.value.evaluate_grouped_by_tag_keys
      granularity                  = strategy.value.granularity
      method                       = strategy.value.method

      dynamic "allocated_by" {
        for_each = strategy.value.allocated_by != null ? strategy.value.allocated_by : []
        content {
          percentage = allocated_by.value.percentage

          dynamic "allocated_tags" {
            for_each = allocated_by.value.allocated_tags != null ? allocated_by.value.allocated_tags : []
            content {
              key   = allocated_tags.value.key
              value = allocated_tags.value.value
            }
          }
        }
      }

      dynamic "allocated_by_filters" {
        for_each = strategy.value.allocated_by_filters != null ? strategy.value.allocated_by_filters : []
        content {
          condition = allocated_by_filters.value.condition
          tag       = allocated_by_filters.value.tag
          value     = allocated_by_filters.value.value
          values    = allocated_by_filters.value.values
        }
      }

      dynamic "based_on_costs" {
        for_each = strategy.value.based_on_costs != null ? strategy.value.based_on_costs : []
        content {
          condition = based_on_costs.value.condition
          tag       = based_on_costs.value.tag
          value     = based_on_costs.value.value
          values    = based_on_costs.value.values
        }
      }

      dynamic "based_on_timeseries" {
        for_each = strategy.value.based_on_timeseries == true ? [1] : []
        content {}
      }

      dynamic "evaluate_grouped_by_filters" {
        for_each = strategy.value.evaluate_grouped_by_filters != null ? strategy.value.evaluate_grouped_by_filters : []
        content {
          condition = evaluate_grouped_by_filters.value.condition
          tag       = evaluate_grouped_by_filters.value.tag
          value     = evaluate_grouped_by_filters.value.value
          values    = evaluate_grouped_by_filters.value.values
        }
      }
    }
  }
}

resource "datadog_custom_allocation_rules" "this" {
  count = var.enable_rule_order ? 1 : 0

  # rule_order holds logical rule names (keys of var.allocation_rules); resolve them to
  # IDs from the sibling resources within this module. Referencing sibling resources
  # (rather than this module's own output) avoids a self-referential dependency cycle.
  rule_ids                      = [for name in var.rule_order : datadog_custom_allocation_rule.this[name].id]
  override_ui_defined_resources = var.override_ui_defined_resources

  lifecycle {
    precondition {
      condition     = length(var.rule_order) > 0
      error_message = "rule_order must be a non-empty list of rule names when enable_rule_order is true. Submitting an empty order (especially with override_ui_defined_resources = true) would make Terraform the source of truth for an empty rule ordering."
    }
  }
}
