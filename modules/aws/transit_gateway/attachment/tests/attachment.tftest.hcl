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

run "baseline_single_attachment_with_defaults" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    enable_flow_logs   = false
    vpc_ids = {
      transit_vpc = {
        subnet_ids = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
        vpc_id     = "vpc-0123456789abcdef0"
      }
    }
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.this) == 1
    error_message = "Expected exactly one transit gateway VPC attachment to be planned."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].appliance_mode_support == "disable"
    error_message = "appliance_mode_support should default to disable."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].dns_support == "enable"
    error_message = "dns_support should default to enable."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].ipv6_support == "disable"
    error_message = "ipv6_support should default to disable."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].transit_gateway_default_route_table_association == true
    error_message = "transit_gateway_default_route_table_association should default to true."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].transit_gateway_default_route_table_propagation == true
    error_message = "transit_gateway_default_route_table_propagation should default to true."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].tags["Name"] == "transit_vpc"
    error_message = "Name tag should default to the map key."
  }

  assert {
    condition     = output.ids["transit_vpc"] == aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].id
    error_message = "ids output should equal the attachment resource's id."
  }

  assert {
    condition     = length(output.ids_list) == 1
    error_message = "ids_list output should contain one entry."
  }
}

run "per_entry_overrides_are_honored" {
  command = plan

  variables {
    transit_gateway_id                              = "tgw-0123456789abcdef0"
    transit_gateway_default_route_table_association = false
    transit_gateway_default_route_table_propagation = false
    enable_flow_logs                                = false
    vpc_ids = {
      transit_vpc = {
        appliance_mode_support = "enable"
        dns_support            = "disable"
        ipv6_support           = "enable"
        subnet_ids             = ["subnet-0123456789abcdef0"]
        vpc_id                 = "vpc-0123456789abcdef0"
      }
    }
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].appliance_mode_support == "enable"
    error_message = "appliance_mode_support override should be honored."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].dns_support == "disable"
    error_message = "dns_support override should be honored."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].ipv6_support == "enable"
    error_message = "ipv6_support override should be honored."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].transit_gateway_default_route_table_association == false
    error_message = "transit_gateway_default_route_table_association override should be honored."
  }

  assert {
    condition     = aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].transit_gateway_default_route_table_propagation == false
    error_message = "transit_gateway_default_route_table_propagation override should be honored."
  }
}

run "for_each_expands_to_one_attachment_per_vpc" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    enable_flow_logs   = false
    vpc_ids = {
      transit_vpc_a = {
        subnet_ids = ["subnet-0123456789abcdef0"]
        vpc_id     = "vpc-0123456789abcdef0"
      }
      transit_vpc_b = {
        subnet_ids = ["subnet-0123456789abcdef1"]
        vpc_id     = "vpc-0123456789abcdef1"
      }
    }
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.this) == 2
    error_message = "Expected one attachment per vpc_ids map entry."
  }

  assert {
    condition     = length(output.ids) == 2
    error_message = "ids output should contain one entry per VPC."
  }

  assert {
    condition     = length(output.info) == 2
    error_message = "info output should contain one entry per VPC."
  }

  assert {
    condition     = output.info["transit_vpc_a"].id == aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc_a"].id
    error_message = "info output's id field should match the attachment resource's id."
  }

  assert {
    condition     = output.info["transit_vpc_a"].transit_gateway_id == var.transit_gateway_id
    error_message = "info output's transit_gateway_id field should match the configured transit_gateway_id."
  }

  assert {
    condition     = output.info["transit_vpc_a"].subnet_ids == aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc_a"].subnet_ids
    error_message = "info output's subnet_ids field should match the attachment resource's subnet_ids."
  }

  assert {
    condition     = output.info["transit_vpc_a"].appliance_mode_support == aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc_a"].appliance_mode_support
    error_message = "info output's appliance_mode_support field should match the attachment resource's appliance_mode_support."
  }

  assert {
    condition     = length(output.vpc_owner_id) == 2
    error_message = "vpc_owner_id output should contain one entry per VPC."
  }

  assert {
    condition     = output.vpc_owner_id[aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc_a"].vpc_id] == aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc_a"].vpc_owner_id
    error_message = "vpc_owner_id output should map each attachment's vpc_id to that attachment resource's vpc_owner_id."
  }
}

run "empty_vpc_ids_map_creates_no_attachments" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    enable_flow_logs   = false
    vpc_ids            = {}
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_vpc_attachment.this) == 0
    error_message = "An empty vpc_ids map should plan zero attachments."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when vpc_ids is empty."
  }

  assert {
    condition     = length(output.ids_list) == 0
    error_message = "ids_list output should be empty when vpc_ids is empty."
  }

  assert {
    condition     = length(output.info) == 0
    error_message = "info output should be empty when vpc_ids is empty."
  }

  assert {
    condition     = length(output.vpc_owner_id) == 0
    error_message = "vpc_owner_id output should be empty when vpc_ids is empty."
  }
}

run "enable_flow_logs_true_creates_flow_logs_module" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    enable_flow_logs   = true
    vpc_ids = {
      transit_vpc = {
        subnet_ids = ["subnet-0123456789abcdef0"]
        vpc_id     = "vpc-0123456789abcdef0"
      }
    }
  }

  assert {
    condition     = length(module.vpc_flow_logs) == 1
    error_message = "enable_flow_logs = true should create exactly one instance of the vpc_flow_logs module."
  }

  assert {
    condition     = module.vpc_flow_logs[0].arn != null
    error_message = "The flow_logs module's arn output should resolve, proving the transit gateway attachment ID wiring succeeded."
  }

  assert {
    condition     = length(module.vpc_flow_logs[0].flow_log_ids) == 1
    error_message = "Exactly one aws_flow_log resource should be created inside the flow_logs module, targeting the transit gateway attachment."
  }

  assert {
    condition     = module.vpc_flow_logs[0].flow_log_transit_gateway_attachment_ids[0] == aws_ec2_transit_gateway_vpc_attachment.this["transit_vpc"].id
    error_message = "The flow log's transit_gateway_attachment_id should equal the attachment resource's id, proving flow_transit_gateway_attachment_ids was actually wired through."
  }
}

run "enable_flow_logs_false_skips_flow_logs_module" {
  command = plan

  variables {
    transit_gateway_id = "tgw-0123456789abcdef0"
    enable_flow_logs   = false
    vpc_ids = {
      transit_vpc = {
        subnet_ids = ["subnet-0123456789abcdef0"]
        vpc_id     = "vpc-0123456789abcdef0"
      }
    }
  }

  assert {
    condition     = length(module.vpc_flow_logs) == 0
    error_message = "enable_flow_logs = false should not create the vpc_flow_logs module."
  }
}
