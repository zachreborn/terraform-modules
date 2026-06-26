###########################
# Resource Variables
###########################

variable "monitors" {
  description = "Map of Datadog monitor configurations keyed by logical name. Each entry maps to one datadog_monitor resource."
  type = map(object({
    ###########################
    # Required Fields
    ###########################
    name    = string
    type    = string
    message = string
    query   = string

    ###########################
    # Optional Fields
    ###########################
    draft_status             = optional(string, "published")
    enable_logs_sample       = optional(bool, false)
    enable_samples           = optional(bool, null)
    escalation_message       = optional(string, null)
    evaluation_delay         = optional(number, null)
    force_delete             = optional(bool, null)
    group_retention_duration = optional(string, null)
    groupby_simple_monitor   = optional(bool, false)
    include_tags             = optional(bool, true)
    new_group_delay          = optional(number, null)
    new_host_delay           = optional(number, null)
    no_data_timeframe        = optional(number, null)
    notification_preset_name = optional(string, null)
    notify_audit             = optional(bool, false)
    notify_by                = optional(set(string), null)
    notify_no_data           = optional(bool, false)
    on_missing_data          = optional(string, null)
    priority                 = optional(string, null)
    renotify_interval        = optional(number, null)
    renotify_occurrences     = optional(number, null)
    renotify_statuses        = optional(set(string), null)
    require_full_window      = optional(bool, true)
    restricted_roles         = optional(set(string), null)
    tags                     = optional(list(string), [])
    timeout_h                = optional(number, null)
    validate                 = optional(bool, null)

    ###########################
    # monitor_thresholds Block
    ###########################
    # All threshold values are strings (not numbers) to support precise decimal representation.
    monitor_thresholds = optional(object({
      critical                = optional(string, null)
      critical_query          = optional(string, null)
      critical_recovery       = optional(string, null)
      critical_recovery_query = optional(string, null)
      ok                      = optional(string, null)
      unknown                 = optional(string, null)
      warning                 = optional(string, null)
      warning_recovery        = optional(string, null)
    }), null)

    ###########################
    # monitor_threshold_windows Block
    ###########################
    # Only valid for anomaly monitors.
    monitor_threshold_windows = optional(object({
      recovery_window = optional(string, null)
      trigger_window  = optional(string, null)
    }), null)

    ###########################
    # scheduling_options Block
    ###########################
    scheduling_options = optional(object({
      # custom_schedule and evaluation_window are mutually exclusive.
      custom_schedule = optional(object({
        recurrence = object({
          rrule    = string
          timezone = string
          start    = optional(string, null)
        })
      }), null)
      evaluation_window = optional(object({
        day_starts   = optional(string, null)
        hour_starts  = optional(number, null)
        month_starts = optional(number, null)
        timezone     = optional(string, null)
      }), null)
    }), null)

    ###########################
    # assets Block
    ###########################
    assets = optional(list(object({
      category      = string
      name          = string
      url           = string
      resource_key  = optional(string, null)
      resource_type = optional(string, null)
    })), null)

    ###########################
    # variables Block
    ###########################
    # Used for formula-based monitors (event query, cloud cost, data jobs, data quality).
    # Note: aggregate_augmented_query and aggregate_filtered_query require module extension.
    variables = optional(object({
      cloud_cost_query = optional(list(object({
        aggregator  = string
        data_source = string
        name        = string
        query       = string
      })), null)
      data_jobs_query = optional(list(object({
        job_type      = string
        jobs_query    = string
        name          = string
        query_dialect = string
      })), null)
      data_quality_query = optional(list(object({
        data_source    = string
        filter         = string
        measure        = string
        name           = string
        group_by       = optional(list(string), null)
        schema_version = optional(string, null)
        scope          = optional(string, null)
        monitor_options = optional(object({
          crontab_override    = optional(string, null)
          custom_sql          = optional(string, null)
          custom_where        = optional(string, null)
          group_by_columns    = optional(list(string), null)
          model_type_override = optional(string, null)
        }), null)
      })), null)
      event_query = optional(list(object({
        data_source = string
        name        = string
        compute = list(object({
          aggregation = string
          interval    = optional(number, null)
          metric      = optional(string, null)
          name        = optional(string, null)
        }))
        search = object({
          query = string
        })
        group_by = optional(list(object({
          facet  = string
          limit  = optional(number, null)
          source = optional(string, null)
          sort = optional(object({
            aggregation = string
            metric      = optional(string, null)
            order       = optional(string, null)
          }), null)
        })), null)
        indexes = optional(list(string), null)
      })), null)
    }), null)
  }))

  validation {
    condition = alltrue([
      for k, v in var.monitors : contains([
        "composite", "event alert", "log alert", "metric alert", "process alert",
        "query alert", "rum alert", "service check", "synthetics alert",
        "trace-analytics alert", "slo alert", "event-v2 alert", "audit alert",
        "ci-pipelines alert", "ci-tests alert", "error-tracking alert",
        "database-monitoring alert", "network-performance alert", "cost alert",
        "data-quality alert", "network-path alert", "data-jobs alert"
      ], v.type)
    ])
    error_message = "Each monitor type must be one of the valid Datadog monitor types: composite, event alert, log alert, metric alert, process alert, query alert, rum alert, service check, synthetics alert, trace-analytics alert, slo alert, event-v2 alert, audit alert, ci-pipelines alert, ci-tests alert, error-tracking alert, database-monitoring alert, network-performance alert, cost alert, data-quality alert, network-path alert, data-jobs alert."
  }

  validation {
    condition = alltrue([
      for k, v in var.monitors : v.priority == null || contains(["1", "2", "3", "4", "5"], v.priority)
    ])
    error_message = "Each monitor priority must be null or one of: '1', '2', '3', '4', '5' (1 = highest, 5 = lowest)."
  }

  validation {
    condition = alltrue([
      for k, v in var.monitors : v.draft_status == null || contains(["draft", "published"], v.draft_status)
    ])
    error_message = "draft_status must be 'draft' or 'published'."
  }

  validation {
    condition = alltrue([
      for k, v in var.monitors : v.on_missing_data == null || contains(["show_no_data", "show_and_notify_no_data", "resolve", "default"], v.on_missing_data)
    ])
    error_message = "on_missing_data must be one of: show_no_data, show_and_notify_no_data, resolve, default."
  }

  validation {
    condition = alltrue([
      for k, v in var.monitors : v.notification_preset_name == null || contains(["show_all", "hide_query", "hide_handles", "hide_all", "hide_query_and_handles", "show_only_snapshot", "hide_handles_and_footer"], v.notification_preset_name)
    ])
    error_message = "notification_preset_name must be one of: show_all, hide_query, hide_handles, hide_all, hide_query_and_handles, show_only_snapshot, hide_handles_and_footer."
  }
}
