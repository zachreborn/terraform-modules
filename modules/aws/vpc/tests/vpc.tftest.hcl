# The nested vpc_flow_logs module (../flow_logs) wires several ARN-typed
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
    name = "core-vpc"
  }

  assert {
    condition     = aws_vpc.vpc.cidr_block == var.vpc_cidr
    error_message = "The VPC's cidr_block should equal the (default) vpc_cidr input."
  }

  assert {
    condition     = length(aws_subnet.private_subnets) == 3
    error_message = "Expected 3 private subnets from the default private_subnets_list."
  }

  assert {
    condition     = length(aws_subnet.public_subnets) == 3
    error_message = "Expected 3 public subnets from the default public_subnets_list."
  }

  assert {
    condition     = length(aws_internet_gateway.igw) == 1
    error_message = "IGW should be created by default (enable_internet_gateway=true and public subnets present)."
  }

  assert {
    condition     = length(aws_nat_gateway.natgw) == 3
    error_message = "Expected one NAT gateway per AZ by default (enable_nat_gateway=true, single_nat_gateway=false)."
  }

  assert {
    condition     = length(aws_eip.nateip) == 3
    error_message = "Expected one EIP per NAT gateway by default."
  }

  assert {
    condition     = length(module.vpc_flow_logs) == 1
    error_message = "Flow logs module should be created by default (enable_flow_logs=true)."
  }

  assert {
    condition     = length(aws_internetmonitor_monitor.this) == 0
    error_message = "Internet Monitor should not be created by default (enable_internet_monitor=false)."
  }

  assert {
    condition     = output.vpc_id != null
    error_message = "vpc_id output should resolve."
  }

  assert {
    condition     = length(output.private_subnet_ids) == 3
    error_message = "private_subnet_ids output should contain 3 entries."
  }

  assert {
    condition     = length(output.public_subnet_ids) == 3
    error_message = "public_subnet_ids output should contain 3 entries."
  }

  assert {
    condition     = length(output.natgw_ids) == 3
    error_message = "natgw_ids output should contain 3 entries."
  }

  assert {
    condition     = length(output.igw_id) == 1
    error_message = "igw_id output should contain 1 entry."
  }

  assert {
    condition     = output.name == "core-vpc"
    error_message = "name output should reflect the Name tag."
  }
}

run "single_nat_gateway_shares_one_nat_and_eip" {
  command = plan

  variables {
    name               = "core-vpc"
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.natgw) == 1
    error_message = "single_nat_gateway=true should collapse to exactly one NAT gateway."
  }

  assert {
    condition     = length(aws_eip.nateip) == 1
    error_message = "single_nat_gateway=true should collapse to exactly one EIP."
  }
}

run "enable_nat_gateway_false_creates_no_nat_resources" {
  command = plan

  variables {
    name               = "core-vpc"
    enable_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.natgw) == 0
    error_message = "enable_nat_gateway=false should create no NAT gateways."
  }

  assert {
    condition     = length(aws_eip.nateip) == 0
    error_message = "enable_nat_gateway=false should create no EIPs."
  }

  assert {
    condition     = length(aws_route.private_default_route_natgw) == 0
    error_message = "enable_nat_gateway=false should create no private default NAT routes."
  }
}

# NOTE: enable_nat_gateway and public_subnets_list are both neutralized below.
# With the default enable_nat_gateway=true and a non-empty public_subnets_list,
# disabling the IGW (via enable_internet_gateway=false, or an empty
# public_subnets_list on its own) crashes plan because several resources (the
# *_default_route_natgw routes and aws_route_table_association.public) key
# their `count` off enable_nat_gateway / subnet-list length alone, without also
# checking local.enable_igw the way aws_nat_gateway.natgw itself does. This is
# a real module bug, filed as https://github.com/zachreborn/terraform-modules/issues/384
# -- not a test bug, so it is not being worked around by editing main.tf here.
run "enable_internet_gateway_false_disables_igw_and_dependent_nat" {
  command = plan

  variables {
    name                    = "core-vpc"
    enable_internet_gateway = false
    enable_nat_gateway      = false
    public_subnets_list     = []
  }

  assert {
    condition     = length(aws_internet_gateway.igw) == 0
    error_message = "enable_internet_gateway=false should create no IGW."
  }

  assert {
    condition     = length(aws_route_table.public_route_table) == 0
    error_message = "enable_internet_gateway=false should create no public route table."
  }

  assert {
    condition     = length(aws_route_table_association.public) == 0
    error_message = "enable_internet_gateway=false should create no public route table associations."
  }
}

# See the note above run "enable_internet_gateway_false_disables_igw_and_dependent_nat":
# enable_nat_gateway is disabled here for the same reason (tracked in issue #384).
run "empty_public_subnets_list_disables_igw_even_when_enabled" {
  command = plan

  variables {
    name                    = "core-vpc"
    enable_internet_gateway = true
    enable_nat_gateway      = false
    public_subnets_list     = []
  }

  assert {
    condition     = length(aws_internet_gateway.igw) == 0
    error_message = "local.enable_igw should be false when public_subnets_list is empty, even if enable_internet_gateway=true."
  }
}

run "ssm_vpc_endpoints_disabled_by_default" {
  command = plan

  variables {
    name = "core-vpc"
  }

  assert {
    condition     = length(aws_vpc_endpoint.ec2messages) == 0
    error_message = "SSM VPC endpoints should be disabled by default."
  }

  assert {
    condition     = length(aws_vpc_endpoint.kms) == 0
    error_message = "SSM VPC endpoints should be disabled by default."
  }

  assert {
    condition     = length(aws_vpc_endpoint.ssm) == 0
    error_message = "SSM VPC endpoints should be disabled by default."
  }
}

run "ssm_vpc_endpoints_enabled_creates_all_six_endpoints" {
  command = plan

  variables {
    name                     = "core-vpc"
    enable_ssm_vpc_endpoints = true
  }

  assert {
    condition     = length(aws_vpc_endpoint.ec2messages) == 1
    error_message = "ec2messages endpoint should be created when enable_ssm_vpc_endpoints=true."
  }

  assert {
    condition     = length(aws_vpc_endpoint.kms) == 1
    error_message = "kms endpoint should be created when enable_ssm_vpc_endpoints=true."
  }

  assert {
    condition     = length(aws_vpc_endpoint.ssm) == 1
    error_message = "ssm endpoint should be created when enable_ssm_vpc_endpoints=true."
  }

  assert {
    condition     = length(aws_vpc_endpoint.ssm-contacts) == 1
    error_message = "ssm-contacts endpoint should be created when enable_ssm_vpc_endpoints=true."
  }

  assert {
    condition     = length(aws_vpc_endpoint.ssm-incidents) == 1
    error_message = "ssm-incidents endpoint should be created when enable_ssm_vpc_endpoints=true."
  }

  assert {
    condition     = length(aws_vpc_endpoint.ssmmessages) == 1
    error_message = "ssmmessages endpoint should be created when enable_ssm_vpc_endpoints=true."
  }
}

run "ecr_vpc_endpoints_disabled_by_default" {
  command = plan

  variables {
    name = "core-vpc"
  }

  assert {
    condition     = length(aws_vpc_endpoint.ecr_api) == 0
    error_message = "ECR VPC endpoints should be disabled by default."
  }

  assert {
    condition     = length(aws_vpc_endpoint.ecr_dkr) == 0
    error_message = "ECR VPC endpoints should be disabled by default."
  }

  assert {
    condition     = length(aws_vpc_endpoint.cloudwatch) == 0
    error_message = "The logs endpoint gated by enable_ecr_vpc_endpoints should be disabled by default."
  }

  assert {
    condition     = length(aws_vpc_endpoint.s3) == 0
    error_message = "S3 endpoint should be disabled by default (enable_s3_endpoint=false and enable_ecr_vpc_endpoints=false)."
  }
}

run "ecr_vpc_endpoints_enabled_creates_ecr_dkr_logs_and_s3" {
  command = plan

  variables {
    name                     = "core-vpc"
    enable_ecr_vpc_endpoints = true
  }

  assert {
    condition     = length(aws_vpc_endpoint.ecr_api) == 1
    error_message = "ecr_api endpoint should be created when enable_ecr_vpc_endpoints=true."
  }

  assert {
    condition     = length(aws_vpc_endpoint.ecr_dkr) == 1
    error_message = "ecr_dkr endpoint should be created when enable_ecr_vpc_endpoints=true."
  }

  assert {
    condition     = length(aws_vpc_endpoint.cloudwatch) == 1
    error_message = "The CloudWatch Logs endpoint should be created when enable_ecr_vpc_endpoints=true."
  }

  assert {
    condition     = length(aws_vpc_endpoint.s3) == 1
    error_message = "enable_ecr_vpc_endpoints=true should also create the S3 gateway endpoint (OR logic with enable_s3_endpoint)."
  }
}

run "s3_endpoint_enabled_independently_of_ecr" {
  command = plan

  variables {
    name               = "core-vpc"
    enable_s3_endpoint = true
  }

  assert {
    condition     = length(aws_vpc_endpoint.s3) == 1
    error_message = "enable_s3_endpoint=true alone should create the S3 gateway endpoint."
  }

  assert {
    condition     = length(aws_vpc_endpoint.ecr_api) == 0
    error_message = "enable_s3_endpoint should not also enable the ECR endpoints."
  }

  assert {
    condition     = length(aws_vpc_endpoint_route_table_association.private_s3) == length(aws_route_table.private_route_table)
    error_message = "Every private route table should get an S3 endpoint association when the S3 endpoint is enabled."
  }

  assert {
    condition     = length(aws_vpc_endpoint_route_table_association.public_s3) == length(aws_route_table.public_route_table)
    error_message = "Every public route table should get an S3 endpoint association when the S3 endpoint is enabled."
  }
}

run "firewall_disabled_by_default_creates_no_fw_routes" {
  command = plan

  variables {
    name = "core-vpc"
  }

  assert {
    condition     = length(aws_route.private_default_route_fw) == 0
    error_message = "enable_firewall should default to false, creating no firewall routes."
  }

  assert {
    condition     = length(aws_route.dmz_default_route_fw) == 0
    error_message = "enable_firewall should default to false, creating no DMZ firewall routes."
  }
}

run "firewall_enabled_creates_one_fw_route_per_az_per_table" {
  command = plan

  variables {
    name                        = "core-vpc"
    enable_firewall             = true
    fw_network_interface_id     = ["eni-0123456789abcdef0", "eni-0123456789abcdef1", "eni-0123456789abcdef2"]
    fw_dmz_network_interface_id = ["eni-0123456789abcdef3", "eni-0123456789abcdef4", "eni-0123456789abcdef5"]
  }

  assert {
    condition     = length(aws_route.private_default_route_fw) == 3
    error_message = "Expected one firewall route per AZ (3) in the private route table."
  }

  assert {
    condition     = length(aws_route.dmz_default_route_fw) == 3
    error_message = "Expected one firewall route per AZ (3) in the DMZ route table."
  }

  assert {
    condition     = length(aws_route.mgmt_default_route_fw) == 3
    error_message = "Expected one firewall route per AZ (3) in the mgmt route table."
  }

  assert {
    condition     = length(aws_route.workspaces_default_route_fw) == 3
    error_message = "Expected one firewall route per AZ (3) in the workspaces route table."
  }
}

run "enable_flow_logs_false_skips_flow_logs_module" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
  }

  assert {
    condition     = length(module.vpc_flow_logs) == 0
    error_message = "enable_flow_logs=false should not create the vpc_flow_logs module."
  }
}

run "enable_flow_logs_true_wires_vpc_id_into_flow_logs_module" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = true
  }

  assert {
    condition     = length(module.vpc_flow_logs) == 1
    error_message = "enable_flow_logs=true should create exactly one instance of the vpc_flow_logs module."
  }

  assert {
    condition     = module.vpc_flow_logs[0].arn != null
    error_message = "The flow_logs module's arn output should resolve, proving flow_vpc_ids wiring (coalesce) succeeded."
  }
}
