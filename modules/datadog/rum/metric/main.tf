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
# Module Configuration
###########################

resource "datadog_rum_metric" "this" {
  for_each = var.metrics

  name       = each.value.name
  event_type = each.value.event_type

  dynamic "compute" {
    for_each = each.value.compute != null ? [each.value.compute] : []
    content {
      aggregation_type    = compute.value.aggregation_type
      include_percentiles = compute.value.include_percentiles
      path                = compute.value.path
    }
  }

  dynamic "filter" {
    for_each = each.value.filter != null ? [each.value.filter] : []
    content {
      query = filter.value.query
    }
  }

  dynamic "group_by" {
    for_each = each.value.group_by != null ? each.value.group_by : []
    content {
      path     = group_by.value.path
      tag_name = group_by.value.tag_name
    }
  }

  dynamic "uniqueness" {
    for_each = each.value.uniqueness != null ? [each.value.uniqueness] : []
    content {
      when = uniqueness.value.when
    }
  }
}
