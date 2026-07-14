# The nested vpc_flow_logs module (../../flow_logs) wires several ARN-typed
# attributes (aws_iam_role.arn, aws_iam_policy.arn, aws_cloudwatch_log_group.arn)
# into other resources' arguments that the AWS provider schema validates as
# well-formed ARNs. mock_provider's default placeholder strings for computed
# attributes are not ARN-shaped, so override them here with valid ARNs.
mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-flow-logs-role"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock-flow-logs-policy"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:mock-flow-logs-group"
    }
  }
}

run "baseline_plans_with_defaults" {
  command = plan

  variables {
    name             = "core-tgw"
    enable_flow_logs = false
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.amazon_side_asn == 64525
    error_message = "amazon_side_asn should default to 64525."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.auto_accept_shared_attachments == "disable"
    error_message = "auto_accept_shared_attachments should default to disable."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.default_route_table_association == "enable"
    error_message = "default_route_table_association should default to enable."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.default_route_table_propagation == "enable"
    error_message = "default_route_table_propagation should default to enable."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.dns_support == "enable"
    error_message = "dns_support should default to enable."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.vpn_ecmp_support == "enable"
    error_message = "vpn_ecmp_support should default to enable."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.transit_gateway_cidr_blocks == null
    error_message = "transit_gateway_cidr_blocks should default to null."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.tags["Name"] == "core-tgw"
    error_message = "Name tag should default to the name variable."
  }

  assert {
    condition     = output.id != null
    error_message = "id output should resolve."
  }

  assert {
    condition     = output.arn != null
    error_message = "arn output should resolve."
  }

  assert {
    condition     = output.bgp_asn == 64525
    error_message = "bgp_asn output should mirror amazon_side_asn."
  }
}

run "overrides_are_honored" {
  command = plan

  variables {
    name                            = "core-tgw"
    enable_flow_logs                = false
    amazon_side_asn                 = "64512"
    auto_accept_shared_attachments  = "enable"
    default_route_table_association = "disable"
    default_route_table_propagation = "disable"
    dns_support                     = "disable"
    vpn_ecmp_support                = "disable"
    transit_gateway_cidr_blocks     = ["172.16.5.0/24"]
    description                     = "Custom description"
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.amazon_side_asn == 64512
    error_message = "amazon_side_asn override should be honored."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.auto_accept_shared_attachments == "enable"
    error_message = "auto_accept_shared_attachments override should be honored."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.default_route_table_association == "disable"
    error_message = "default_route_table_association override should be honored."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.default_route_table_propagation == "disable"
    error_message = "default_route_table_propagation override should be honored."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.dns_support == "disable"
    error_message = "dns_support override should be honored."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.vpn_ecmp_support == "disable"
    error_message = "vpn_ecmp_support override should be honored."
  }

  assert {
    condition     = length(aws_ec2_transit_gateway.transit_gateway.transit_gateway_cidr_blocks) == 1
    error_message = "transit_gateway_cidr_blocks override should be honored (expected exactly one CIDR block, matching the override)."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.description == "Custom description"
    error_message = "description override should be honored."
  }
}

run "tags_merge_module_and_provided_tags" {
  command = plan

  variables {
    name             = "core-tgw"
    enable_flow_logs = false
    tags = {
      team = "networking"
    }
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.tags["team"] == "networking"
    error_message = "Caller-provided tags should be merged in."
  }

  assert {
    condition     = aws_ec2_transit_gateway.transit_gateway.tags["Name"] == "core-tgw"
    error_message = "Name tag should still be present alongside merged tags."
  }
}

run "enable_flow_logs_true_creates_flow_logs_module" {
  command = plan

  variables {
    name             = "core-tgw"
    enable_flow_logs = true
  }

  assert {
    condition     = length(module.vpc_flow_logs) == 1
    error_message = "enable_flow_logs = true should create exactly one instance of the vpc_flow_logs module."
  }

  assert {
    condition     = module.vpc_flow_logs[0].arn != null
    error_message = "The flow_logs module's arn output should resolve, proving the transit gateway ID wiring succeeded."
  }
}

run "enable_flow_logs_false_skips_flow_logs_module" {
  command = plan

  variables {
    name             = "core-tgw"
    enable_flow_logs = false
  }

  assert {
    condition     = length(module.vpc_flow_logs) == 0
    error_message = "enable_flow_logs = false should not create the vpc_flow_logs module."
  }
}
