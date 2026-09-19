mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    connection_id = "dxcon-example1"
    dx_gateway_id = "abcd1234-dcba-5678-be23-cdef9876ab45"
    name          = "example-transit-vif"
    vlan          = 100
    bgp_asn       = 65000
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.vlan == 100
    error_message = "Expected the virtual interface to be planned with the given vlan."
  }
}

run "rejects_vlan_below_minimum" {
  command = plan

  variables {
    connection_id = "dxcon-example1"
    dx_gateway_id = "abcd1234-dcba-5678-be23-cdef9876ab45"
    name          = "example-transit-vif"
    vlan          = 0
    bgp_asn       = 65000
  }

  expect_failures = [var.vlan]
}

run "rejects_vlan_above_maximum" {
  command = plan

  variables {
    connection_id = "dxcon-example1"
    dx_gateway_id = "abcd1234-dcba-5678-be23-cdef9876ab45"
    name          = "example-transit-vif"
    vlan          = 4095
    bgp_asn       = 65000
  }

  expect_failures = [var.vlan]
}

run "rejects_invalid_address_family" {
  command = plan

  variables {
    connection_id  = "dxcon-example1"
    dx_gateway_id  = "abcd1234-dcba-5678-be23-cdef9876ab45"
    name           = "example-transit-vif"
    vlan           = 100
    bgp_asn        = 65000
    address_family = "ipv5"
  }

  expect_failures = [var.address_family]
}

run "rejects_invalid_mtu" {
  command = plan

  variables {
    connection_id = "dxcon-example1"
    dx_gateway_id = "abcd1234-dcba-5678-be23-cdef9876ab45"
    name          = "example-transit-vif"
    vlan          = 100
    bgp_asn       = 65000
    mtu           = 9000
  }

  expect_failures = [var.mtu]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
