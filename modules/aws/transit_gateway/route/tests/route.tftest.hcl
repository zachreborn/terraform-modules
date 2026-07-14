mock_provider "aws" {}

run "baseline_plans_with_single_destination" {
  command = plan

  variables {
    destination_cidr_blocks        = ["10.0.0.0/16"]
    transit_gateway_attachment_id  = "tgw-attach-0123456789abcdef0"
    transit_gateway_route_table_id = "tgw-rtb-0123456789abcdef0"
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_route.this) == 1
    error_message = "Expected exactly one route to be planned for a single destination CIDR."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route.this["10.0.0.0/16"].blackhole == false
    error_message = "blackhole should default to false."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route.this["10.0.0.0/16"].transit_gateway_attachment_id == "tgw-attach-0123456789abcdef0"
    error_message = "transit_gateway_attachment_id should pass through unchanged."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route.this["10.0.0.0/16"].transit_gateway_route_table_id == "tgw-rtb-0123456789abcdef0"
    error_message = "transit_gateway_route_table_id should pass through unchanged."
  }

  assert {
    condition     = output.routes["10.0.0.0/16"] == "tgw-attach-0123456789abcdef0"
    error_message = "routes output should map the destination CIDR to its attachment ID."
  }
}

run "for_each_expands_to_one_route_per_destination" {
  command = plan

  variables {
    destination_cidr_blocks        = ["10.0.0.0/16", "10.1.0.0/16", "10.2.0.0/16"]
    transit_gateway_attachment_id  = "tgw-attach-0123456789abcdef0"
    transit_gateway_route_table_id = "tgw-rtb-0123456789abcdef0"
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_route.this) == 3
    error_message = "Expected one route per destination CIDR block."
  }

  assert {
    condition     = length(output.routes) == 3
    error_message = "routes output should contain one entry per destination CIDR block."
  }
}

run "empty_destination_set_plans_zero_routes" {
  command = plan

  variables {
    destination_cidr_blocks        = []
    transit_gateway_attachment_id  = "tgw-attach-0123456789abcdef0"
    transit_gateway_route_table_id = "tgw-rtb-0123456789abcdef0"
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_route.this) == 0
    error_message = "An empty destination_cidr_blocks set should plan zero routes."
  }

  assert {
    condition     = length(output.routes) == 0
    error_message = "routes output should be empty when no destinations are configured."
  }
}

run "blackhole_true_does_not_require_an_attachment" {
  command = plan

  variables {
    destination_cidr_blocks        = ["0.0.0.0/0"]
    blackhole                      = true
    transit_gateway_attachment_id  = null
    transit_gateway_route_table_id = "tgw-rtb-0123456789abcdef0"
  }

  assert {
    condition     = aws_ec2_transit_gateway_route.this["0.0.0.0/0"].blackhole == true
    error_message = "blackhole override should be honored."
  }

  assert {
    condition     = aws_ec2_transit_gateway_route.this["0.0.0.0/0"].transit_gateway_attachment_id == null
    error_message = "transit_gateway_attachment_id should remain null for a blackhole route."
  }
}
