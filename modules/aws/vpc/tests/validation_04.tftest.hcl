mock_provider "aws" {}



run "rejects_additional_routes_with_two_targets" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    additional_routes = {
      bad = {
        route_table_types         = ["private"]
        destination_cidr_block    = cidrsubnet(var.private_subnets_list[0], 4, 1)
        vpc_peering_connection_id = "pcx-0123456789abcdef0"
        transit_gateway_id        = "tgw-0123456789abcdef0"
      }
    }
  }

  expect_failures = [var.additional_routes]
}

run "rejects_vpc_endpoints_entry_with_identifier_type_mismatch" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    vpc_endpoints = {
      bad = {
        resource_configuration_arn = "arn:aws:vpc-lattice:us-east-1:123456789012:resourceconfiguration/rcfg-0123456789abcdef0"
        vpc_endpoint_type          = "Interface"
      }
    }
  }

  expect_failures = [var.vpc_endpoints]
}

run "rejects_vpc_endpoints_subnet_configuration_id_not_in_subnet_ids" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    vpc_endpoints = {
      bad = {
        service_name = "com.amazonaws.us-east-1.secretsmanager"
        subnet_ids   = ["subnet-0123456789abcdef0"]
        subnet_configuration = [
          {
            subnet_id = "subnet-fedcba9876543210f"
          }
        ]
      }
    }
  }

  expect_failures = [var.vpc_endpoints]
}

# security_group_ids is only applicable to Interface endpoints (AWS provider
# docs); a Gateway endpoint supplying one should be rejected at validation
# time instead of failing later at apply.
run "rejects_vpc_endpoints_security_group_ids_on_non_interface_type" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    vpc_endpoints = {
      bad = {
        service_name       = "com.amazonaws.us-east-1.dynamodb"
        vpc_endpoint_type  = "Gateway"
        security_group_ids = ["sg-0123456789abcdef0"]
      }
    }
  }

  expect_failures = [var.vpc_endpoints]
}

# route_table_ids is only applicable to Gateway endpoints (AWS provider
# docs); an Interface endpoint supplying one should be rejected at
# validation time instead of failing later at apply.
run "rejects_vpc_endpoints_route_table_ids_on_non_gateway_type" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    vpc_endpoints = {
      bad = {
        service_name        = "com.amazonaws.us-east-1.secretsmanager"
        vpc_endpoint_type   = "Interface"
        private_dns_enabled = true
        route_table_ids     = ["rtb-0123456789abcdef0"]
      }
    }
  }

  expect_failures = [var.vpc_endpoints]
}

# GatewayLoadBalancer endpoints accept exactly one subnet; supplying more
# than one should be rejected at validation time instead of failing later
# at apply.
run "rejects_vpc_endpoints_gatewayloadbalancer_with_multiple_subnets" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    vpc_endpoints = {
      bad = {
        service_name      = "com.amazonaws.vpce.us-east-1.vpce-svc-0123456789abcdef0"
        vpc_endpoint_type = "GatewayLoadBalancer"
        subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
      }
    }
  }

  expect_failures = [var.vpc_endpoints]
}

# With no managed private subnets to default to, an Interface endpoint that
# omits subnet_ids would otherwise silently plan with an empty subnet set
# and fail at apply; reject it at validation time instead.
run "rejects_vpc_endpoints_interface_type_without_subnets_when_private_subnets_list_is_empty" {
  command = plan

  variables {
    name                 = "core-vpc"
    enable_flow_logs     = false
    private_subnets_list = []
    subnet_indices       = []
    vpc_endpoints = {
      bad = {
        service_name        = "com.amazonaws.us-east-1.secretsmanager"
        vpc_endpoint_type   = "Interface"
        private_dns_enabled = true
      }
    }
  }

  expect_failures = [var.vpc_endpoints]
}

# With no managed private subnets to default to, a GatewayLoadBalancer
# endpoint that omits subnet_ids would otherwise index an empty fallback
# list and fail during planning; reject it at validation time instead.
run "rejects_vpc_endpoints_gatewayloadbalancer_without_subnets_when_private_subnets_list_is_empty" {
  command = plan

  variables {
    name                 = "core-vpc"
    enable_flow_logs     = false
    private_subnets_list = []
    subnet_indices       = []
    vpc_endpoints = {
      bad = {
        service_name      = "com.amazonaws.vpce.us-east-1.vpce-svc-0123456789abcdef0"
        vpc_endpoint_type = "GatewayLoadBalancer"
      }
    }
  }

  expect_failures = [var.vpc_endpoints]
}

# A Gateway endpoint doesn't need subnet_ids at all, so an empty
# private_subnets_list should not affect it.
run "accepts_vpc_endpoints_gateway_type_when_private_subnets_list_is_empty" {
  command = plan

  variables {
    name                 = "core-vpc"
    enable_flow_logs     = false
    private_subnets_list = []
    subnet_indices       = []
    vpc_endpoints = {
      good = {
        service_name      = "com.amazonaws.us-east-1.dynamodb"
        vpc_endpoint_type = "Gateway"
      }
    }
  }

  assert {
    condition     = length(aws_vpc_endpoint.custom) == 1
    error_message = "A Gateway endpoint should plan successfully even when private_subnets_list is empty, since it doesn't use subnet_ids."
  }
}
