# aws_vpc.ipv6_cidr_block is Optional+Computed. When it's sourced from
# assign_generated_ipv6_cidr_block or an IPAM pool (no explicit
# ipv6_cidr_block in config), it has no value in configuration for
# mock_provider to echo back, so those specific runs below use a per-run
# override_resource block to give it a realistic /56 -- this lets
# cidrsubnet() in main.tf compute real /64 values for every subnet during
# `plan`. This can't be a single file-level mock_resource.defaults block
# (as tests/internet_monitor.tftest.hcl does for aws_vpc.arn) because some
# runs in this file (the explicit_ipv6_cidr_block_* runs) set ipv6_cidr_block
# directly in config, and OpenTofu rejects a mock/override default for an
# attribute that's already explicitly configured.
mock_provider "aws" {}

run "ipv6_disabled_by_default_creates_no_ipv6_resources" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
  }

  # assign_generated_ipv6_cidr_block resolves to null (not false) when
  # inactive, so that it never collides with ipv6_ipam_pool_id's provider-level
  # ConflictsWith validation (see the comment on this attribute in main.tf).
  assert {
    condition     = aws_vpc.vpc.assign_generated_ipv6_cidr_block == null
    error_message = "assign_generated_ipv6_cidr_block should resolve to null (inactive) when enable_ipv6 is false."
  }

  assert {
    condition     = length(aws_egress_only_internet_gateway.eigw) == 0
    error_message = "No egress-only internet gateway should be created when enable_ipv6 is false."
  }

  # Note: aws_subnet.ipv6_cidr_block is Optional+Computed, so mock_provider
  # cannot reliably represent "this resolves to a real null" here (a
  # config-computed null on an Optional+Computed attribute is mock-filled
  # with placeholder data regardless of the config expression's value).
  # assign_ipv6_address_on_creation is a plain Optional bool (not Computed),
  # so it IS reliably mockable and is the correct signal to assert on here.
  assert {
    condition     = aws_subnet.private_subnets[0].assign_ipv6_address_on_creation == false
    error_message = "Private subnets should not auto-assign IPv6 addresses by default."
  }

  assert {
    condition     = length(aws_route.public_default_route_ipv6) == 0
    error_message = "No IPv6 default route should be created on the public route table by default."
  }

  assert {
    condition     = length(aws_route.private_default_route_ipv6) == 0
    error_message = "No IPv6 default route should be created on private route tables by default."
  }

  # output.vpc_ipv6_cidr_block is likewise skipped for the same Optional+Computed
  # reason as aws_subnet.ipv6_cidr_block above; egress_only_internet_gateway_id
  # IS reliably assertable since it's derived from one(aws_egress_only_internet_gateway.eigw[*].id),
  # and that resource's count (asserted above) is a real, non-computed 0.
  assert {
    condition     = output.egress_only_internet_gateway_id == null
    error_message = "egress_only_internet_gateway_id output should be null when enable_ipv6 is false."
  }
}

run "enable_ipv6_assigns_generated_cidr_and_dual_stacks_every_subnet" {
  command = plan

  variables {
    name             = "core-vpc"
    enable_flow_logs = false
    enable_ipv6      = true
  }

  override_resource {
    target = aws_vpc.vpc
    values = {
      ipv6_cidr_block = "2600:1f16:abc:d800::/56"
    }
  }

  assert {
    condition     = aws_vpc.vpc.assign_generated_ipv6_cidr_block == true
    error_message = "enable_ipv6=true without an IPv6 IPAM pool should request an Amazon-provided IPv6 CIDR."
  }

  assert {
    condition     = length(aws_egress_only_internet_gateway.eigw) == 1
    error_message = "An egress-only internet gateway should be created when enable_ipv6 is true."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.private_subnets : s.assign_ipv6_address_on_creation == true])
    error_message = "Every private subnet should auto-assign IPv6 addresses when enable_ipv6 is true."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.private_subnets : s.ipv6_cidr_block != null])
    error_message = "Every private subnet should receive a computed /64 IPv6 CIDR when enable_ipv6 is true."
  }

  assert {
    condition     = length(distinct(concat(aws_subnet.private_subnets[*].ipv6_cidr_block, aws_subnet.public_subnets[*].ipv6_cidr_block))) == length(aws_subnet.private_subnets) + length(aws_subnet.public_subnets)
    error_message = "Every subnet across tiers should receive a unique /64, proving the per-tier offset math doesn't collide."
  }

  assert {
    condition     = length(aws_route.public_default_route_ipv6) == 1
    error_message = "The public route table should get exactly one IPv6 default route via the IGW."
  }

  assert {
    condition     = aws_route.public_default_route_ipv6[0].gateway_id == aws_internet_gateway.igw[0].id
    error_message = "The public IPv6 default route should target the internet gateway."
  }

  assert {
    condition     = length(aws_route.private_default_route_ipv6) == length(aws_route_table.private_route_table)
    error_message = "Private IPv6 default route count should match the number of private route tables, not length(var.azs) (they happen to be equal with defaults, but must not be conflated)."
  }

  assert {
    condition     = aws_route.private_default_route_ipv6[0].egress_only_gateway_id == aws_egress_only_internet_gateway.eigw[0].id
    error_message = "Private IPv6 default routes should target the egress-only internet gateway, not a NAT gateway (NAT doesn't support IPv6)."
  }

  assert {
    condition     = output.vpc_ipv6_cidr_block == aws_vpc.vpc.ipv6_cidr_block
    error_message = "vpc_ipv6_cidr_block output should resolve to the VPC's IPv6 CIDR when enabled."
  }

  assert {
    condition     = output.egress_only_internet_gateway_id == aws_egress_only_internet_gateway.eigw[0].id
    error_message = "egress_only_internet_gateway_id output should resolve when enable_ipv6 is true."
  }
}

run "enable_ipv6_with_ipam_pool_sources_cidr_from_pool_instead_of_auto_assign" {
  command = plan

  variables {
    name              = "core-vpc"
    enable_flow_logs  = false
    enable_ipv6       = true
    ipv6_ipam_pool_id = "ipam-pool-0123456789abcdef1"
  }

  override_resource {
    target = aws_vpc.vpc
    values = {
      ipv6_cidr_block = "2600:1f16:abc:d800::/56"
    }
  }

  assert {
    condition     = aws_vpc.vpc.ipv6_ipam_pool_id == "ipam-pool-0123456789abcdef1"
    error_message = "ipv6_ipam_pool_id should pass through unchanged."
  }

  assert {
    condition     = aws_vpc.vpc.ipv6_netmask_length == 56
    error_message = "ipv6_netmask_length should default to 56 (the fixed Amazon-provided prefix length) when using an IPAM pool without an explicit override."
  }
}

run "enable_ipv6_disables_only_igw_still_skips_public_ipv6_route" {
  command = plan

  variables {
    name                    = "core-vpc"
    enable_flow_logs        = false
    enable_ipv6             = true
    enable_internet_gateway = false
  }

  override_resource {
    target = aws_vpc.vpc
    values = {
      ipv6_cidr_block = "2600:1f16:abc:d800::/56"
    }
  }

  assert {
    condition     = length(aws_route.public_default_route_ipv6) == 0
    error_message = "The public IPv6 default route depends on the IGW, so it should be skipped when the IGW is disabled, even with enable_ipv6=true."
  }

  assert {
    condition     = length(aws_route.private_default_route_ipv6) == length(aws_route_table.private_route_table)
    error_message = "Private-tier IPv6 default routes use the egress-only gateway (independent of the IGW), so they should still be created."
  }
}

# Regression test for the fix to aws_vpc.vpc.ipv6_netmask_length/ipv6_cidr_block:
# passing both simultaneously triggers the AWS provider's ConflictsWith
# validation between them.
run "explicit_ipv6_cidr_block_does_not_conflict_with_netmask_length" {
  command = plan

  variables {
    name              = "core-vpc"
    enable_flow_logs  = false
    enable_ipv6       = true
    ipv6_ipam_pool_id = "ipam-pool-0123456789abcdef1"
    ipv6_cidr_block   = "2600:1f16:abc:d800::/56"
  }

  assert {
    condition     = aws_vpc.vpc.ipv6_netmask_length == null
    error_message = "ipv6_netmask_length must resolve to null when ipv6_cidr_block is explicitly set, since the AWS provider treats them as mutually exclusive."
  }

  assert {
    condition     = aws_vpc.vpc.ipv6_cidr_block == "2600:1f16:abc:d800::/56"
    error_message = "The explicit ipv6_cidr_block should pass through unchanged."
  }
}

# Regression test for deriving the /64 carve-out math from the explicit
# ipv6_cidr_block's own prefix length, rather than always assuming
# ipv6_netmask_length (default 56). A /60 explicit CIDR only has 16 /64s
# available; this module's default subnet layout needs more than that, so
# the capacity precondition on aws_vpc.vpc should now correctly catch it
# using the derived /60 prefix (it would incorrectly pass if the prefix were
# still derived from the unset ipv6_netmask_length default of 56).
run "explicit_ipv6_cidr_block_prefix_drives_capacity_precondition" {
  command = plan

  variables {
    name              = "core-vpc"
    enable_flow_logs  = false
    enable_ipv6       = true
    ipv6_ipam_pool_id = "ipam-pool-0123456789abcdef1"
    ipv6_cidr_block   = "2600:1f16:abc:d800::/60"
  }

  expect_failures = [aws_vpc.vpc]
}

# Regression test for the fix to the private/db/dmz/mgmt/workspaces IPv6
# default route count+indexing: it must match each tier's own route table
# count, not length(var.azs). Extends each tier's subnet list by one entry
# (4 subnets across the default 3 AZs) to exercise the mismatch directly.
run "ipv6_default_routes_match_route_table_count_not_az_count" {
  command = plan

  variables {
    name                    = "core-vpc"
    enable_flow_logs        = false
    enable_ipv6             = true
    private_subnets_list    = concat(var.private_subnets_list, [cidrsubnet(var.private_subnets_list[0], 1, 1)])
    db_subnets_list         = concat(var.db_subnets_list, [cidrsubnet(var.db_subnets_list[0], 1, 1)])
    dmz_subnets_list        = concat(var.dmz_subnets_list, [cidrsubnet(var.dmz_subnets_list[0], 1, 1)])
    mgmt_subnets_list       = concat(var.mgmt_subnets_list, [cidrsubnet(var.mgmt_subnets_list[0], 1, 1)])
    workspaces_subnets_list = concat(var.workspaces_subnets_list, [cidrsubnet(var.workspaces_subnets_list[0], 1, 1)])
  }

  override_resource {
    target = aws_vpc.vpc
    values = {
      ipv6_cidr_block = "2600:1f16:abc:d800::/56"
    }
  }

  # mock_provider assigns the same placeholder id to every instance of a
  # count-based resource, so a distinct-route_table_id assertion can't
  # reliably distinguish a correct per-index mapping from a buggy wrapped
  # one under mock. The count assertions here are what actually prove the
  # fix: previously this count was length(var.azs)=3; it now correctly
  # matches each tier's real route table count (4, since these tests extend
  # every tier's subnet list by one entry beyond the default 3 AZs).
  assert {
    condition     = length(aws_route.private_default_route_ipv6) == length(aws_route_table.private_route_table)
    error_message = "private IPv6 default route count (4) should match the number of private route tables (4), not length(var.azs) (3)."
  }

  assert {
    condition     = length(aws_route.db_default_route_ipv6) == length(aws_route_table.db_route_table)
    error_message = "db IPv6 default route count should match the number of db route tables."
  }

  assert {
    condition     = length(aws_route.dmz_default_route_ipv6) == length(aws_route_table.dmz_route_table)
    error_message = "dmz IPv6 default route count should match the number of dmz route tables."
  }

  assert {
    condition     = length(aws_route.mgmt_default_route_ipv6) == length(aws_route_table.mgmt_route_table)
    error_message = "mgmt IPv6 default route count should match the number of mgmt route tables."
  }

  assert {
    condition     = length(aws_route.workspaces_default_route_ipv6) == length(aws_route_table.workspaces_route_table)
    error_message = "workspaces IPv6 default route count should match the number of workspaces route tables."
  }
}
