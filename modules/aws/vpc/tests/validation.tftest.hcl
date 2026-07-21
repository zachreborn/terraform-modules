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

run "rejects_subnet_index_above_range" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    subnet_indices   = [3]
  }

  expect_failures = [var.subnet_indices]
}

run "rejects_subnet_index_below_range" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    subnet_indices   = [-1]
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

# Regression test for the previously-hardcoded "0 to 2" cap on subnet_indices
# (fixed to be dynamic: 0 to length(private_subnets_list) - 1). Extend the
# module's own default private_subnets_list by one entry (rather than
# hardcoding a new CIDR literal) so subnet_indices can reference index 3,
# which used to be rejected unconditionally regardless of how many private
# subnets were actually configured.
run "accepts_subnet_index_beyond_old_hardcoded_cap_when_private_subnets_list_is_longer" {
  command = plan

  variables {
    name                 = "core-vpc"
    enable_flow_logs     = false
    private_subnets_list = concat(var.private_subnets_list, [cidrsubnet(var.private_subnets_list[0], 1, 1)])
    subnet_indices       = [3]
  }

  assert {
    condition     = aws_vpc.vpc.cidr_block == var.vpc_cidr
    error_message = "subnet_indices=[3] should now pass validation when private_subnets_list has 4 entries, and the rest of the plan should proceed normally."
  }
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

run "rejects_additional_routes_with_unsupported_tier_name" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    additional_routes = {
      bad = {
        route_table_types      = ["privte"]
        destination_cidr_block = "192.0.2.0/24"
      }
    }
  }

  expect_failures = [var.additional_routes]
}

run "rejects_additional_routes_with_empty_route_table_types" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    additional_routes = {
      bad = {
        route_table_types      = []
        destination_cidr_block = "192.0.2.0/24"
      }
    }
  }

  expect_failures = [var.additional_routes]
}

run "rejects_additional_routes_with_duplicate_route_table_types" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    additional_routes = {
      bad = {
        route_table_types      = ["private", "private"]
        destination_cidr_block = "192.0.2.0/24"
      }
    }
  }

  expect_failures = [var.additional_routes]
}

run "rejects_vpc_endpoints_entry_with_no_identifier" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    vpc_endpoints = {
      bad = {}
    }
  }

  expect_failures = [var.vpc_endpoints]
}

run "rejects_vpc_endpoints_entry_with_two_identifiers" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    vpc_endpoints = {
      bad = {
        service_name               = "com.amazonaws.us-east-1.secretsmanager"
        resource_configuration_arn = "arn:aws:vpc-lattice:us-east-1:123456789012:resourceconfiguration/rcfg-0123456789abcdef0"
      }
    }
  }

  expect_failures = [var.vpc_endpoints]
}

run "rejects_vpc_endpoints_entry_with_invalid_type" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    vpc_endpoints = {
      bad = {
        service_name      = "com.amazonaws.us-east-1.secretsmanager"
        vpc_endpoint_type = "Bogus"
      }
    }
  }

  expect_failures = [var.vpc_endpoints]
}
