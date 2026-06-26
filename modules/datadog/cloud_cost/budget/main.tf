###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.1.5"
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
resource "datadog_cost_budget" "this" {
  for_each = var.budgets

  name          = each.value.name
  metrics_query = each.value.metrics_query
  start_month   = each.value.start_month
  end_month     = each.value.end_month

  dynamic "budget_line" {
    for_each = each.value.budget_lines != null ? each.value.budget_lines : []
    content {
      amounts = budget_line.value.amounts

      dynamic "tag_filters" {
        for_each = budget_line.value.tag_filters != null ? budget_line.value.tag_filters : []
        content {
          tag_key   = tag_filters.value.tag_key
          tag_value = tag_filters.value.tag_value
        }
      }

      dynamic "parent_tag_filters" {
        for_each = budget_line.value.parent_tag_filters != null ? budget_line.value.parent_tag_filters : []
        content {
          tag_key   = parent_tag_filters.value.tag_key
          tag_value = parent_tag_filters.value.tag_value
        }
      }

      dynamic "child_tag_filters" {
        for_each = budget_line.value.child_tag_filters != null ? budget_line.value.child_tag_filters : []
        content {
          tag_key   = child_tag_filters.value.tag_key
          tag_value = child_tag_filters.value.tag_value
        }
      }
    }
  }

  dynamic "entries" {
    for_each = each.value.entries != null ? each.value.entries : []
    content {
      month  = entries.value.month
      amount = entries.value.amount

      dynamic "tag_filters" {
        for_each = entries.value.tag_filters != null ? entries.value.tag_filters : []
        content {
          tag_key   = tag_filters.value.tag_key
          tag_value = tag_filters.value.tag_value
        }
      }
    }
  }
}
