mock_provider "aws" {}



run "rejects_internet_monitor_traffic_percentage_above_range" {
  command = plan

  variables {
    name                                           = "core-vpc"
    enable_flow_logs                               = false
    internet_monitor_traffic_percentage_to_monitor = 101
  }

  expect_failures = [var.internet_monitor_traffic_percentage_to_monitor]
}

run "rejects_internet_monitor_max_city_networks_below_range" {
  command = plan

  variables {
    name                                          = "core-vpc"
    enable_flow_logs                              = false
    internet_monitor_max_city_networks_to_monitor = 0
  }

  expect_failures = [var.internet_monitor_max_city_networks_to_monitor]
}

run "rejects_internet_monitor_max_city_networks_above_range" {
  command = plan

  variables {
    name                                          = "core-vpc"
    enable_flow_logs                              = false
    internet_monitor_max_city_networks_to_monitor = 500001
  }

  expect_failures = [var.internet_monitor_max_city_networks_to_monitor]
}

run "rejects_invalid_internet_monitor_status" {
  command = plan

  variables {
    name                    = "core-vpc"
    enable_flow_logs        = false
    internet_monitor_status = "PAUSED"
  }

  expect_failures = [var.internet_monitor_status]
}

run "rejects_internet_monitor_availability_score_threshold_below_range" {
  command = plan

  variables {
    name                                          = "core-vpc"
    enable_flow_logs                              = false
    internet_monitor_availability_score_threshold = 0
  }

  expect_failures = [var.internet_monitor_availability_score_threshold]
}

run "rejects_internet_monitor_availability_score_threshold_above_range" {
  command = plan

  variables {
    name                                          = "core-vpc"
    enable_flow_logs                              = false
    internet_monitor_availability_score_threshold = 101
  }

  expect_failures = [var.internet_monitor_availability_score_threshold]
}

run "rejects_internet_monitor_performance_score_threshold_below_range" {
  command = plan

  variables {
    name                                         = "core-vpc"
    enable_flow_logs                             = false
    internet_monitor_performance_score_threshold = 0
  }

  expect_failures = [var.internet_monitor_performance_score_threshold]
}

run "rejects_internet_monitor_performance_score_threshold_above_range" {
  command = plan

  variables {
    name                                         = "core-vpc"
    enable_flow_logs                             = false
    internet_monitor_performance_score_threshold = 101
  }

  expect_failures = [var.internet_monitor_performance_score_threshold]
}

run "rejects_invalid_internet_monitor_s3_bucket_status" {
  command = plan

  variables {
    name                              = "core-vpc"
    enable_flow_logs                  = false
    internet_monitor_s3_bucket_status = "MAYBE"
  }

  expect_failures = [var.internet_monitor_s3_bucket_status]
}

run "rejects_additional_routes_with_unsupported_tier_name" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    additional_routes = {
      bad = {
        route_table_types      = ["bogus"]
        destination_cidr_block = "192.0.2.0/24"
      }
    }
  }

  expect_failures = [var.additional_routes]
}