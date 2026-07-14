mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
  }

  assert {
    condition     = aws_vpc.vpc.cidr_block == var.vpc_cidr
    error_message = "Default inputs should satisfy every validation block and plan successfully."
  }
}

run "rejects_invalid_instance_tenancy" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    instance_tenancy = "host"
  }

  expect_failures = [var.instance_tenancy]
}

run "rejects_subnet_index_out_of_range" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    subnet_indices   = [3]
  }

  expect_failures = [var.subnet_indices]
}

run "rejects_subnet_indices_longer_than_private_subnets_list" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    # Truncate the module's own default private_subnets_list to 2 entries
    # (rather than hardcoding new CIDR literals) so subnet_indices (3 entries)
    # ends up longer than private_subnets_list, tripping the length check.
    private_subnets_list = slice(var.private_subnets_list, 0, 2)
    subnet_indices       = [0, 1, 2]
  }

  expect_failures = [var.subnet_indices]
}

run "rejects_invalid_cloudwatch_retention_in_days" {
  command = plan

  variables {
    name                         = "core-vpc"
    enable_flow_logs             = false
    cloudwatch_retention_in_days = 45
  }

  expect_failures = [var.cloudwatch_retention_in_days]
}

run "rejects_invalid_flow_traffic_type" {
  command = plan

  variables {
    name              = "core-vpc"
    enable_flow_logs  = false
    flow_traffic_type = "SOMETHING"
  }

  expect_failures = [var.flow_traffic_type]
}

run "rejects_internet_monitor_traffic_percentage_below_range" {
  command = plan

  variables {
    name                                           = "core-vpc"
    enable_flow_logs                               = false
    internet_monitor_traffic_percentage_to_monitor = 0
  }

  expect_failures = [var.internet_monitor_traffic_percentage_to_monitor]
}

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
