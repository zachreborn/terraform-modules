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

# Regression test: aws_subnet.private_subnets assigns AZs via
# element(var.azs, count.index), which cycles once there are more private
# subnets than AZs. With the default 3 AZs and a 4th private subnet added,
# indices 0 and 3 both land on azs[0] -- selecting both would place two
# subnets from the same AZ behind each SSM interface endpoint.
run "rejects_subnet_indices_selecting_duplicate_az" {
  command = plan

  variables {
    name                 = "core-vpc"
    enable_flow_logs     = false
    private_subnets_list = concat(var.private_subnets_list, [cidrsubnet(var.private_subnets_list[0], 1, 1)])
    subnet_indices       = [0, 3]
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