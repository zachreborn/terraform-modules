mock_provider "aws" {}



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

run "rejects_subnet_indices_with_duplicate_values" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    subnet_indices   = [0, 0]
  }

  expect_failures = [var.subnet_indices]
}

run "rejects_subnet_indices_with_fractional_value" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    subnet_indices   = [0.5]
  }

  expect_failures = [var.subnet_indices]
}

run "rejects_additional_routes_with_no_destination" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    additional_routes = {
      bad = {
        route_table_types         = ["private"]
        vpc_peering_connection_id = "pcx-0123456789abcdef0"
      }
    }
  }

  expect_failures = [var.additional_routes]
}

run "rejects_additional_routes_with_two_destinations" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    additional_routes = {
      bad = {
        route_table_types           = ["private"]
        destination_cidr_block      = cidrsubnet(var.private_subnets_list[0], 4, 1)
        destination_ipv6_cidr_block = "2600:1f16:abc:d800::/64"
        vpc_peering_connection_id   = "pcx-0123456789abcdef0"
      }
    }
  }

  expect_failures = [var.additional_routes]
}

run "rejects_additional_routes_with_no_target" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    additional_routes = {
      bad = {
        route_table_types      = ["private"]
        destination_cidr_block = cidrsubnet(var.private_subnets_list[0], 4, 1)
      }
    }
  }

  expect_failures = [var.additional_routes]
}