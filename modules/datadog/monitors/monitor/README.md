<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Datadog Monitor</h3>
  <p align="center">
    Manages Datadog monitors (datadog_monitor) supporting all monitor types with full schema coverage.
    <br />
    <a href="https://github.com/zachreborn/terraform-modules"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://zacharyhill.co">Zachary Hill</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Report Bug</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#description">Description</a></li>
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#Resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Description

This module manages one or more [Datadog monitors](https://docs.datadoghq.com/monitors/) (`datadog_monitor`). It supports all monitor types — metric, log, APM, RUM, synthetics, SLO, composite, and more — through a single `map(object)` variable so you can scale to any number of monitors without duplicating module blocks.

Full schema coverage includes:
- All direct attributes (thresholds, notification settings, scheduling, tagging)
- Nested `monitor_thresholds`, `monitor_threshold_windows`, `scheduling_options`, and `assets` blocks
- Formula query `variables` block (event query, cloud cost, data jobs, data quality sub-types)

## Prerequisites

- A Datadog account with an API key and Application key configured in the provider.
- The Datadog Terraform provider (`DataDog/datadog >= 4.0.0`) configured in the calling module or root.

## Usage

### Metric alert monitor

```hcl
module "cpu_monitors" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/monitors/monitor"

  monitors = {
    high_cpu = {
      name    = "High CPU usage"
      type    = "metric alert"
      message = "CPU usage is critically high on {{host.name}}. Notify: @pagerduty-platform"
      query   = "avg(last_5m):avg:system.cpu.user{env:prod} by {host} > 90"

      monitor_thresholds = {
        critical = "90"
        warning  = "80"
      }

      notify_no_data    = true
      no_data_timeframe = 10
      tags              = ["env:prod", "team:platform"]
    }
  }
}
```

### Log alert monitor with escalation

```hcl
module "error_log_monitors" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/monitors/monitor"

  monitors = {
    high_error_rate = {
      name               = "High error rate in application logs"
      type               = "log alert"
      message            = "Error rate is above threshold. @slack-ops-channel"
      escalation_message = "Error rate still elevated after 30 minutes! @pagerduty"
      query              = "logs(\"status:error service:my-app\").index(\"*\").rollup(\"count\").last(\"5m\") > 100"

      monitor_thresholds = {
        critical = "100"
        warning  = "50"
      }

      priority          = "2"
      notify_audit      = true
      renotify_interval = 30
      renotify_statuses = ["alert", "warn"]
      tags              = ["env:prod", "service:my-app"]
    }
  }
}
```

### Anomaly monitor with threshold windows

```hcl
module "anomaly_monitors" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/monitors/monitor"

  monitors = {
    request_anomaly = {
      name    = "Anomalous request rate"
      type    = "metric alert"
      message = "Anomalous request rate detected. @slack-engineering"
      query   = "avg(last_4h):anomalies(avg:trace.rack.request.hits{env:prod}.as_rate(), 'basic', 2, direction='both', alert_window='last_15m', interval=60, count_default_zero='true') >= 1"

      monitor_thresholds = {
        critical          = "1.0"
        critical_recovery = "0.0"
      }

      monitor_threshold_windows = {
        trigger_window  = "last_15m"
        recovery_window = "last_15m"
      }

      tags = ["env:prod", "team:backend"]
    }
  }
}
```

### Monitor with custom schedule

```hcl
module "scheduled_monitors" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/monitors/monitor"

  monitors = {
    weekly_batch = {
      name    = "Weekly batch job failure"
      type    = "metric alert"
      message = "Weekly batch job has failed. @oncall-data"
      query   = "sum(last_1h):sum:batch.job.failures{env:prod} > 0"

      monitor_thresholds = {
        critical = "0"
      }

      scheduling_options = {
        custom_schedule = {
          recurrence = {
            rrule    = "FREQ=WEEKLY;BYDAY=MO"
            timezone = "America/New_York"
            start    = "2024-01-01T08:00:00"
          }
        }
      }

      require_full_window = false
      tags                = ["env:prod", "team:data"]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **`required_version >= 1.1.5`**: The Datadog provider requires Terraform/OpenTofu 1.1.5+ to support certain provider features. This is stricter than the default `>= 1.0.0` used in AWS modules.
- **Threshold values are strings**: The `monitor_thresholds` block uses `string` type (not `number`) for `critical`, `warning`, etc. This matches the Datadog provider schema and avoids floating-point precision issues (e.g., `"90"` instead of `90`).
- **`validate` attribute**: When set to `false`, the Datadog provider skips query validation at plan time. This is useful for dynamic queries or when developing new monitor types. It defaults to `null` (validation enabled).
- **`new_host_delay` is deprecated**: The provider defaults this to `300` seconds. Prefer using `new_group_delay` instead. Set `new_host_delay = 0` explicitly only if you need to override the provider default back to zero.
- **`restricted_roles` is deprecated**: Use the `datadog_restriction_policy` resource instead for permission management.
- **`variables` block**: Supports `event_query`, `cloud_cost_query`, `data_jobs_query`, and `data_quality_query` sub-types for formula-based monitors. The `aggregate_augmented_query` and `aggregate_filtered_query` sub-types are not yet implemented in this module due to their high complexity; extend `variables.tf` and `main.tf` to add them if needed.
- **Tags**: Datadog tags use `list(string)` with `"key:value"` format (e.g., `["env:prod", "team:platform"]`), not the `map(string)` pattern used by AWS modules.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.5 |
| <a name="requirement_datadog"></a> [datadog](#requirement\_datadog) | >= 4.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_datadog"></a> [datadog](#provider\_datadog) | 4.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [datadog_monitor.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/monitor) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_monitors"></a> [monitors](#input\_monitors) | Map of Datadog monitor configurations keyed by logical name. Each entry maps to one datadog\_monitor resource. | <pre>map(object({<br/>    ###########################<br/>    # Required Fields<br/>    ###########################<br/>    name    = string<br/>    type    = string<br/>    message = string<br/>    query   = string<br/><br/>    ###########################<br/>    # Optional Fields<br/>    ###########################<br/>    draft_status             = optional(string, "published")<br/>    enable_logs_sample       = optional(bool, false)<br/>    enable_samples           = optional(bool, null)<br/>    escalation_message       = optional(string, null)<br/>    evaluation_delay         = optional(number, null)<br/>    force_delete             = optional(bool, null)<br/>    group_retention_duration = optional(string, null)<br/>    groupby_simple_monitor   = optional(bool, false)<br/>    include_tags             = optional(bool, true)<br/>    new_group_delay          = optional(number, null)<br/>    new_host_delay           = optional(number, null)<br/>    no_data_timeframe        = optional(number, null)<br/>    notification_preset_name = optional(string, null)<br/>    notify_audit             = optional(bool, false)<br/>    notify_by                = optional(set(string), null)<br/>    notify_no_data           = optional(bool, false)<br/>    on_missing_data          = optional(string, null)<br/>    priority                 = optional(string, null)<br/>    renotify_interval        = optional(number, null)<br/>    renotify_occurrences     = optional(number, null)<br/>    renotify_statuses        = optional(set(string), null)<br/>    require_full_window      = optional(bool, true)<br/>    restricted_roles         = optional(set(string), null)<br/>    tags                     = optional(list(string), [])<br/>    timeout_h                = optional(number, null)<br/>    validate                 = optional(bool, null)<br/><br/>    ###########################<br/>    # monitor_thresholds Block<br/>    ###########################<br/>    # All threshold values are strings (not numbers) to support precise decimal representation.<br/>    monitor_thresholds = optional(object({<br/>      critical                = optional(string, null)<br/>      critical_query          = optional(string, null)<br/>      critical_recovery       = optional(string, null)<br/>      critical_recovery_query = optional(string, null)<br/>      ok                      = optional(string, null)<br/>      unknown                 = optional(string, null)<br/>      warning                 = optional(string, null)<br/>      warning_recovery        = optional(string, null)<br/>    }), null)<br/><br/>    ###########################<br/>    # monitor_threshold_windows Block<br/>    ###########################<br/>    # Only valid for anomaly monitors.<br/>    monitor_threshold_windows = optional(object({<br/>      recovery_window = optional(string, null)<br/>      trigger_window  = optional(string, null)<br/>    }), null)<br/><br/>    ###########################<br/>    # scheduling_options Block<br/>    ###########################<br/>    scheduling_options = optional(object({<br/>      # custom_schedule and evaluation_window are mutually exclusive.<br/>      custom_schedule = optional(object({<br/>        recurrence = object({<br/>          rrule    = string<br/>          timezone = string<br/>          start    = optional(string, null)<br/>        })<br/>      }), null)<br/>      evaluation_window = optional(object({<br/>        day_starts   = optional(string, null)<br/>        hour_starts  = optional(number, null)<br/>        month_starts = optional(number, null)<br/>        timezone     = optional(string, null)<br/>      }), null)<br/>    }), null)<br/><br/>    ###########################<br/>    # assets Block<br/>    ###########################<br/>    assets = optional(list(object({<br/>      category      = string<br/>      name          = string<br/>      url           = string<br/>      resource_key  = optional(string, null)<br/>      resource_type = optional(string, null)<br/>    })), null)<br/><br/>    ###########################<br/>    # variables Block<br/>    ###########################<br/>    # Used for formula-based monitors (event query, cloud cost, data jobs, data quality).<br/>    # Note: aggregate_augmented_query and aggregate_filtered_query require module extension.<br/>    variables = optional(object({<br/>      cloud_cost_query = optional(list(object({<br/>        aggregator  = string<br/>        data_source = string<br/>        name        = string<br/>        query       = string<br/>      })), null)<br/>      data_jobs_query = optional(list(object({<br/>        job_type      = string<br/>        jobs_query    = string<br/>        name          = string<br/>        query_dialect = string<br/>      })), null)<br/>      data_quality_query = optional(list(object({<br/>        data_source    = string<br/>        filter         = string<br/>        measure        = string<br/>        name           = string<br/>        group_by       = optional(list(string), null)<br/>        schema_version = optional(string, null)<br/>        scope          = optional(string, null)<br/>        monitor_options = optional(object({<br/>          crontab_override    = optional(string, null)<br/>          custom_sql          = optional(string, null)<br/>          custom_where        = optional(string, null)<br/>          group_by_columns    = optional(list(string), null)<br/>          model_type_override = optional(string, null)<br/>        }), null)<br/>      })), null)<br/>      event_query = optional(list(object({<br/>        data_source = string<br/>        name        = string<br/>        compute = list(object({<br/>          aggregation = string<br/>          interval    = optional(number, null)<br/>          metric      = optional(string, null)<br/>          name        = optional(string, null)<br/>        }))<br/>        search = object({<br/>          query = string<br/>        })<br/>        group_by = optional(list(object({<br/>          facet  = string<br/>          limit  = optional(number, null)<br/>          source = optional(string, null)<br/>          sort = optional(object({<br/>            aggregation = string<br/>            metric      = optional(string, null)<br/>            order       = optional(string, null)<br/>          }), null)<br/>        })), null)<br/>        indexes = optional(list(string), null)<br/>      })), null)<br/>    }), null)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of monitor logical names to their Datadog monitor IDs. |
| <a name="output_monitors"></a> [monitors](#output\_monitors) | Full map of all datadog\_monitor resource objects, keyed by logical name. |
| <a name="output_names"></a> [names](#output\_names) | Map of monitor logical names to their Datadog monitor display names. |
<!-- END_TF_DOCS -->

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/zachreborn/terraform-modules.svg?style=for-the-badge
[contributors-url]: https://github.com/zachreborn/terraform-modules/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/zachreborn/terraform-modules.svg?style=for-the-badge
[forks-url]: https://github.com/zachreborn/terraform-modules/network/members
[stars-shield]: https://img.shields.io/github/stars/zachreborn/terraform-modules.svg?style=for-the-badge
[stars-url]: https://github.com/zachreborn/terraform-modules/stargazers
[issues-shield]: https://img.shields.io/github/issues/zachreborn/terraform-modules.svg?style=for-the-badge
[issues-url]: https://github.com/zachreborn/terraform-modules/issues
[license-shield]: https://img.shields.io/github/license/zachreborn/terraform-modules.svg?style=for-the-badge
[license-url]: https://github.com/zachreborn/terraform-modules/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
[product-screenshot]: /images/screenshot.webp
[Terraform.io]: https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform
[Terraform-url]: https://terraform.io
