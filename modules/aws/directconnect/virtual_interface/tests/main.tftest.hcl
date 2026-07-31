# Native OpenTofu tests for the directconnect/virtual_interface module. All cases run
# fully offline via `mock_provider`/`mock_resource` -- no real credentials or backend
# required:
#   tofu init -backend=false && tofu test
#
# See AGENTS.md > Module Design Specifications > Native Test Coverage for the full
# requirement, and modules/aws/organizations/account/tests/ for a worked example.

mock_provider "aws" {
  mock_resource "aws_dx_private_virtual_interface" {
    defaults = {
      id              = "dxvif-fgnsp5rq"
      arn             = "arn:aws:directconnect:us-east-1:123456789012:dxvif/dxvif-fgnsp5rq"
      amazon_side_asn = 64512
      tags_all        = {}
    }
  }
  mock_resource "aws_dx_public_virtual_interface" {
    defaults = {
      id              = "dxvif-fgcd7fnk"
      arn             = "arn:aws:directconnect:us-east-1:123456789012:dxvif/dxvif-fgcd7fnk"
      amazon_side_asn = 64512
      tags_all        = {}
    }
  }
  mock_resource "aws_dx_transit_virtual_interface" {
    defaults = {
      id              = "dxvif-fg5vm4l6"
      arn             = "arn:aws:directconnect:us-east-1:123456789012:dxvif/dxvif-fg5vm4l6"
      amazon_side_asn = 64512
      tags_all        = {}
    }
  }
}

###########################
# Private VIF
###########################

run "plan_succeeds_private_with_vpn_gateway" {
  command = plan

  variables {
    vif_type         = "private"
    vif_name         = "my-private-vif"
    dx_connection_id = "dxcon-fguhmqlc"
    vlan             = 100
    customer_bgp_asn = 65000
    vpn_gateway_id   = "vgw-12345678"
  }

  assert {
    condition     = length(aws_dx_private_virtual_interface.this) == 1
    error_message = "Expected exactly one private VIF to be planned."
  }
}

run "plan_succeeds_private_with_direct_connect_gateway" {
  command = plan

  variables {
    vif_type                  = "private"
    vif_name                  = "my-private-vif-dxgw"
    dx_connection_id          = "dxcon-fguhmqlc"
    vlan                      = 101
    customer_bgp_asn          = 65000
    direct_connect_gateway_id = "dx-gateway-12345678"
    mtu                       = 9001
    sitelink_enabled          = true
  }

  assert {
    condition     = aws_dx_private_virtual_interface.this[0].mtu == 9001
    error_message = "mtu should be forwarded to the resource."
  }

  assert {
    condition     = aws_dx_private_virtual_interface.this[0].sitelink_enabled == true
    error_message = "sitelink_enabled should be forwarded to the resource."
  }
}

run "rejects_private_without_any_gateway" {
  command = plan

  variables {
    vif_type         = "private"
    vif_name         = "my-private-vif"
    dx_connection_id = "dxcon-fguhmqlc"
    vlan             = 100
    customer_bgp_asn = 65000
  }

  expect_failures = [aws_dx_private_virtual_interface.this]
}

run "rejects_private_with_both_gateways" {
  command = plan

  variables {
    vif_type                  = "private"
    vif_name                  = "my-private-vif"
    dx_connection_id          = "dxcon-fguhmqlc"
    vlan                      = 100
    customer_bgp_asn          = 65000
    vpn_gateway_id            = "vgw-12345678"
    direct_connect_gateway_id = "dx-gateway-12345678"
  }

  expect_failures = [aws_dx_private_virtual_interface.this]
}

###########################
# Public VIF
###########################

run "plan_succeeds_public_with_route_filter_prefixes" {
  command = plan

  variables {
    vif_type              = "public"
    vif_name              = "my-public-vif"
    dx_connection_id      = "dxcon-fguhmqlc"
    vlan                  = 200
    customer_bgp_asn      = 65000
    route_filter_prefixes = ["2001:db8::/32"]
  }

  assert {
    condition     = length(aws_dx_public_virtual_interface.this) == 1
    error_message = "Expected exactly one public VIF to be planned."
  }
}

run "rejects_public_without_route_filter_prefixes" {
  command = plan

  variables {
    vif_type         = "public"
    vif_name         = "my-public-vif"
    dx_connection_id = "dxcon-fguhmqlc"
    vlan             = 200
    customer_bgp_asn = 65000
  }

  expect_failures = [aws_dx_public_virtual_interface.this]
}

###########################
# Transit VIF
###########################

run "plan_succeeds_transit_with_direct_connect_gateway" {
  command = plan

  variables {
    vif_type                  = "transit"
    vif_name                  = "my-transit-vif"
    dx_connection_id          = "dxcon-fguhmqlc"
    vlan                      = 300
    customer_bgp_asn          = 65000
    direct_connect_gateway_id = "dx-gateway-12345678"
  }

  assert {
    condition     = length(aws_dx_transit_virtual_interface.this) == 1
    error_message = "Expected exactly one transit VIF to be planned."
  }
}

run "rejects_transit_without_direct_connect_gateway" {
  command = plan

  variables {
    vif_type         = "transit"
    vif_name         = "my-transit-vif"
    dx_connection_id = "dxcon-fguhmqlc"
    vlan             = 300
    customer_bgp_asn = 65000
  }

  expect_failures = [aws_dx_transit_virtual_interface.this]
}

###########################
# Variable validation failures
###########################

run "rejects_invalid_vif_type" {
  command = plan

  variables {
    vif_type         = "hybrid"
    vif_name         = "my-vif"
    dx_connection_id = "dxcon-fguhmqlc"
    vlan             = 100
    customer_bgp_asn = 65000
  }

  expect_failures = [var.vif_type]
}

run "rejects_vlan_out_of_range" {
  command = plan

  variables {
    vif_type         = "private"
    vif_name         = "my-vif"
    dx_connection_id = "dxcon-fguhmqlc"
    vlan             = 5000
    customer_bgp_asn = 65000
    vpn_gateway_id   = "vgw-12345678"
  }

  expect_failures = [var.vlan]
}

run "rejects_invalid_address_family" {
  command = plan

  variables {
    vif_type         = "private"
    vif_name         = "my-vif"
    dx_connection_id = "dxcon-fguhmqlc"
    vlan             = 100
    customer_bgp_asn = 65000
    vpn_gateway_id   = "vgw-12345678"
    address_family   = "ipv5"
  }

  expect_failures = [var.address_family]
}

run "rejects_invalid_mtu" {
  command = plan

  variables {
    vif_type         = "private"
    vif_name         = "my-vif"
    dx_connection_id = "dxcon-fguhmqlc"
    vlan             = 100
    customer_bgp_asn = 65000
    vpn_gateway_id   = "vgw-12345678"
    mtu              = 4470
  }

  expect_failures = [var.mtu]
}

###########################
# Outputs
###########################

run "outputs_are_populated_for_private_vif" {
  command = apply

  variables {
    vif_type         = "private"
    vif_name         = "my-private-vif"
    dx_connection_id = "dxcon-fguhmqlc"
    vlan             = 100
    customer_bgp_asn = 65000
    vpn_gateway_id   = "vgw-12345678"
  }

  assert {
    condition     = output.vif_id == "dxvif-fgnsp5rq"
    error_message = "vif_id should resolve to the private VIF ID."
  }

  assert {
    condition     = output.private_vif_id == "dxvif-fgnsp5rq"
    error_message = "private_vif_id should be populated."
  }

  assert {
    condition     = output.public_vif_id == null
    error_message = "public_vif_id should be null when vif_type is private."
  }

  assert {
    condition     = output.bgp_asn == 65000
    error_message = "bgp_asn output should reflect the actual bgp_asn attribute, not customer_address."
  }

  assert {
    condition     = output.amazon_side_asn == "64512"
    error_message = "amazon_side_asn output should be populated."
  }
}

# Do NOT weaken these assertions to force a pass. A failing test is a signal that
# something is wrong in main.tf/variables.tf/outputs.tf -- fix the root cause there.
