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

resource "datadog_monitor" "this" {
  for_each = var.monitors

  name    = each.value.name
  type    = each.value.type
  message = each.value.message
  query   = each.value.query

  draft_status             = each.value.draft_status
  enable_logs_sample       = each.value.enable_logs_sample
  enable_samples           = each.value.enable_samples
  escalation_message       = each.value.escalation_message
  evaluation_delay         = each.value.evaluation_delay
  force_delete             = each.value.force_delete
  group_retention_duration = each.value.group_retention_duration
  groupby_simple_monitor   = each.value.groupby_simple_monitor
  include_tags             = each.value.include_tags
  new_group_delay          = each.value.new_group_delay
  new_host_delay           = each.value.new_host_delay
  no_data_timeframe        = each.value.no_data_timeframe
  notification_preset_name = each.value.notification_preset_name
  notify_audit             = each.value.notify_audit
  notify_by                = each.value.notify_by
  notify_no_data           = each.value.notify_no_data
  on_missing_data          = each.value.on_missing_data
  priority                 = each.value.priority
  renotify_interval        = each.value.renotify_interval
  renotify_occurrences     = each.value.renotify_occurrences
  renotify_statuses        = each.value.renotify_statuses
  require_full_window      = each.value.require_full_window
  restricted_roles         = each.value.restricted_roles
  tags                     = each.value.tags
  timeout_h                = each.value.timeout_h
  validate                 = each.value.validate

  dynamic "assets" {
    for_each = each.value.assets != null ? each.value.assets : []
    content {
      category      = assets.value.category
      name          = assets.value.name
      url           = assets.value.url
      resource_key  = assets.value.resource_key
      resource_type = assets.value.resource_type
    }
  }

  dynamic "monitor_thresholds" {
    for_each = each.value.monitor_thresholds != null ? [each.value.monitor_thresholds] : []
    content {
      critical                = monitor_thresholds.value.critical
      critical_query          = monitor_thresholds.value.critical_query
      critical_recovery       = monitor_thresholds.value.critical_recovery
      critical_recovery_query = monitor_thresholds.value.critical_recovery_query
      ok                      = monitor_thresholds.value.ok
      unknown                 = monitor_thresholds.value.unknown
      warning                 = monitor_thresholds.value.warning
      warning_recovery        = monitor_thresholds.value.warning_recovery
    }
  }

  dynamic "monitor_threshold_windows" {
    for_each = each.value.monitor_threshold_windows != null ? [each.value.monitor_threshold_windows] : []
    content {
      recovery_window = monitor_threshold_windows.value.recovery_window
      trigger_window  = monitor_threshold_windows.value.trigger_window
    }
  }

  dynamic "scheduling_options" {
    for_each = each.value.scheduling_options != null ? [each.value.scheduling_options] : []
    content {
      dynamic "custom_schedule" {
        for_each = scheduling_options.value.custom_schedule != null ? [scheduling_options.value.custom_schedule] : []
        content {
          recurrence {
            rrule    = custom_schedule.value.recurrence.rrule
            timezone = custom_schedule.value.recurrence.timezone
            start    = custom_schedule.value.recurrence.start
          }
        }
      }
      dynamic "evaluation_window" {
        for_each = scheduling_options.value.evaluation_window != null ? [scheduling_options.value.evaluation_window] : []
        content {
          day_starts   = evaluation_window.value.day_starts
          hour_starts  = evaluation_window.value.hour_starts
          month_starts = evaluation_window.value.month_starts
          timezone     = evaluation_window.value.timezone
        }
      }
    }
  }

  dynamic "variables" {
    for_each = each.value.variables != null ? [each.value.variables] : []
    content {
      dynamic "cloud_cost_query" {
        for_each = variables.value.cloud_cost_query != null ? variables.value.cloud_cost_query : []
        content {
          aggregator  = cloud_cost_query.value.aggregator
          data_source = cloud_cost_query.value.data_source
          name        = cloud_cost_query.value.name
          query       = cloud_cost_query.value.query
        }
      }
      dynamic "data_jobs_query" {
        for_each = variables.value.data_jobs_query != null ? variables.value.data_jobs_query : []
        content {
          job_type      = data_jobs_query.value.job_type
          jobs_query    = data_jobs_query.value.jobs_query
          name          = data_jobs_query.value.name
          query_dialect = data_jobs_query.value.query_dialect
        }
      }
      dynamic "data_quality_query" {
        for_each = variables.value.data_quality_query != null ? variables.value.data_quality_query : []
        content {
          data_source    = data_quality_query.value.data_source
          filter         = data_quality_query.value.filter
          measure        = data_quality_query.value.measure
          name           = data_quality_query.value.name
          group_by       = data_quality_query.value.group_by
          schema_version = data_quality_query.value.schema_version
          scope          = data_quality_query.value.scope
          dynamic "monitor_options" {
            for_each = data_quality_query.value.monitor_options != null ? [data_quality_query.value.monitor_options] : []
            content {
              crontab_override    = monitor_options.value.crontab_override
              custom_sql          = monitor_options.value.custom_sql
              custom_where        = monitor_options.value.custom_where
              group_by_columns    = monitor_options.value.group_by_columns
              model_type_override = monitor_options.value.model_type_override
            }
          }
        }
      }
      dynamic "event_query" {
        for_each = variables.value.event_query != null ? variables.value.event_query : []
        content {
          data_source = event_query.value.data_source
          name        = event_query.value.name
          indexes     = event_query.value.indexes
          search {
            query = event_query.value.search.query
          }
          dynamic "compute" {
            for_each = event_query.value.compute
            content {
              aggregation = compute.value.aggregation
              interval    = compute.value.interval
              metric      = compute.value.metric
              name        = compute.value.name
            }
          }
          dynamic "group_by" {
            for_each = event_query.value.group_by != null ? event_query.value.group_by : []
            content {
              facet  = group_by.value.facet
              limit  = group_by.value.limit
              source = group_by.value.source
              dynamic "sort" {
                for_each = group_by.value.sort != null ? [group_by.value.sort] : []
                content {
                  aggregation = sort.value.aggregation
                  metric      = sort.value.metric
                  order       = sort.value.order
                }
              }
            }
          }
        }
      }
    }
  }
}
