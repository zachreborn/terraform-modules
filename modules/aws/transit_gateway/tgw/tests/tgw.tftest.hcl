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
    condition     = output.id == aws_ec2_transit_gateway.transit_gateway.id
    error_message = "id output should equal the transit gateway resource's id."
  }

  assert {
    condition     = output.arn == aws_ec2_transit_gateway.transit_gateway.arn
    error_message = "arn output should equal the transit gateway resource's arn."
  }

  assert {
    condition     = output.bgp_asn == aws_ec2_transit_gateway.transit_gateway.amazon_side_asn
    error_message = "bgp_asn output should mirror amazon_side_asn."
  }

  assert {
    condition     = output.association_default_route_table_id == aws_ec2_transit_gateway.transit_gateway.association_default_route_table_id
    error_message = "association_default_route_table_id output should equal the transit gateway resource's association_default_route_table_id."
  }

  assert {
    condition     = output.propagation_default_route_table_id == aws_ec2_transit_gateway.transit_gateway.propagation_default_route_table_id
    error_message = "propagation_default_route_table_id output should equal the transit gateway resource's propagation_default_route_table_id."
  }

  assert {
    condition     = output.transit_gateway_cidr_blocks == aws_ec2_transit_gateway.transit_gateway.transit_gateway_cidr_blocks
    error_message = "transit_gateway_cidr_blocks output should equal the transit gateway resource's transit_gateway_cidr_blocks (both null by default)."
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

  assert {
    condition     = length(module.vpc_flow_logs[0].flow_log_ids) == 1
    error_message = "Exactly one aws_flow_log resource should be created inside the flow_logs module, targeting the transit gateway."
  }

  assert {
    condition     = module.vpc_flow_logs[0].flow_log_transit_gateway_ids[0] == aws_ec2_transit_gateway.transit_gateway.id
    error_message = "The flow log's transit_gateway_id should equal the transit gateway resource's id, proving flow_transit_gateway_ids was actually wired through."
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
