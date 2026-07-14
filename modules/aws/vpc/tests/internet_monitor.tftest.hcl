# aws_internetmonitor_monitor.resources requires a well-formed ARN; mock_provider's
# default placeholder for aws_vpc.arn is not ARN-shaped, so override it here.
mock_provider "aws" {
  mock_resource "aws_vpc" {
    defaults = {
      arn = "arn:aws:ec2:us-east-1:123456789012:vpc/vpc-0123456789abcdef0"
    }
  }
}

run "internet_monitor_disabled_by_default" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
  }

  assert {
    condition     = length(aws_internetmonitor_monitor.this) == 0
    error_message = "enable_internet_monitor should default to false."
  }

  assert {
    condition     = output.internet_monitor_arn == null
    error_message = "internet_monitor_arn output should be null when the monitor is not created."
  }

  assert {
    condition     = output.internet_monitor_id == null
    error_message = "internet_monitor_id output should be null when the monitor is not created."
  }
}

run "internet_monitor_enabled_with_name_plans_successfully" {
  command = plan

  variables {
    name                          = "core-vpc"
    enable_flow_logs              = false
    enable_internet_monitor       = true
    internet_monitor_monitor_name = "core-vpc-monitor"
  }

  assert {
    condition     = length(aws_internetmonitor_monitor.this) == 1
    error_message = "enable_internet_monitor=true with a monitor name should create exactly one monitor."
  }

  assert {
    condition     = aws_internetmonitor_monitor.this[0].monitor_name == "core-vpc-monitor"
    error_message = "monitor_name should pass through unchanged."
  }

  assert {
    condition     = aws_internetmonitor_monitor.this[0].status == "ACTIVE"
    error_message = "status should default to ACTIVE."
  }

  assert {
    condition     = aws_internetmonitor_monitor.this[0].traffic_percentage_to_monitor == 100
    error_message = "traffic_percentage_to_monitor should default to 100."
  }

  assert {
    condition     = aws_internetmonitor_monitor.this[0].max_city_networks_to_monitor == 100
    error_message = "max_city_networks_to_monitor should default to 100."
  }

  assert {
    condition     = output.internet_monitor_arn != null
    error_message = "internet_monitor_arn output should resolve when the monitor is created."
  }

  assert {
    condition     = output.internet_monitor_id != null
    error_message = "internet_monitor_id output should resolve when the monitor is created."
  }
}

run "internet_monitor_enabled_without_name_fails_precondition" {
  command = plan

  variables {
    name                    = "core-vpc"
    enable_flow_logs        = false
    enable_internet_monitor = true
  }

  expect_failures = [aws_internetmonitor_monitor.this]
}

run "internet_monitor_s3_delivery_configured_when_bucket_name_set" {
  command = plan

  variables {
    name                              = "core-vpc"
    enable_flow_logs                  = false
    enable_internet_monitor           = true
    internet_monitor_monitor_name     = "core-vpc-monitor"
    internet_monitor_s3_bucket_name   = "core-vpc-internet-monitor-logs"
    internet_monitor_s3_bucket_prefix = "internet-monitor/"
    internet_monitor_s3_bucket_status = "ENABLED"
  }

  assert {
    condition     = length(aws_internetmonitor_monitor.this[0].internet_measurements_log_delivery) == 1
    error_message = "The dynamic internet_measurements_log_delivery block should be populated when internet_monitor_s3_bucket_name is set."
  }
}

run "internet_monitor_s3_delivery_omitted_when_bucket_name_unset" {
  command = plan

  variables {
    name                          = "core-vpc"
    enable_flow_logs              = false
    enable_internet_monitor       = true
    internet_monitor_monitor_name = "core-vpc-monitor"
  }

  assert {
    condition     = length(aws_internetmonitor_monitor.this[0].internet_measurements_log_delivery) == 0
    error_message = "The dynamic internet_measurements_log_delivery block should be empty when internet_monitor_s3_bucket_name is unset."
  }
}

run "internet_monitor_threshold_overrides_are_honored" {
  command = plan

  variables {
    name                                           = "core-vpc"
    enable_flow_logs                               = false
    enable_internet_monitor                        = true
    internet_monitor_monitor_name                  = "core-vpc-monitor"
    internet_monitor_status                        = "INACTIVE"
    internet_monitor_traffic_percentage_to_monitor = 50
    internet_monitor_max_city_networks_to_monitor  = 250000
    internet_monitor_availability_score_threshold  = 90
    internet_monitor_performance_score_threshold   = 85
  }

  assert {
    condition     = aws_internetmonitor_monitor.this[0].status == "INACTIVE"
    error_message = "status override should be honored."
  }

  assert {
    condition     = aws_internetmonitor_monitor.this[0].traffic_percentage_to_monitor == 50
    error_message = "traffic_percentage_to_monitor override should be honored."
  }

  assert {
    condition     = aws_internetmonitor_monitor.this[0].max_city_networks_to_monitor == 250000
    error_message = "max_city_networks_to_monitor override should be honored."
  }

  assert {
    condition     = aws_internetmonitor_monitor.this[0].health_events_config[0].availability_score_threshold == 90
    error_message = "internet_monitor_availability_score_threshold override should be honored."
  }

  assert {
    condition     = aws_internetmonitor_monitor.this[0].health_events_config[0].performance_score_threshold == 85
    error_message = "internet_monitor_performance_score_threshold override should be honored."
  }
}
