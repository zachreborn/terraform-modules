###########################
# Resource Outputs
###########################

output "ids" {
  description = "Map of retention filter logical name to retention filter ID."
  value       = { for k, v in datadog_rum_retention_filter.this : k => v.id }
}

output "filter_order_id" {
  description = "ID of the retention filters order resource. Only set when enable_filter_order is true."
  value       = var.enable_filter_order ? datadog_rum_retention_filters_order.this[0].id : null
}
