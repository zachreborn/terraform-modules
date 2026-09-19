mock_provider "aws" {
  mock_resource "aws_dx_transit_virtual_interface" {
    defaults = {
      id                  = "dxvif-mock1234"
      arn                 = "arn:aws:directconnect:us-east-1:123456789012:dxvif/dxvif-mock1234"
      aws_device          = "EqDC2-1abc2def"
      jumbo_frame_capable = true
      amazon_side_asn     = "64512"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    connection_id = "dxcon-example1"
    dx_gateway_id = "abcd1234-dcba-5678-be23-cdef9876ab45"
    name          = "example-transit-vif"
    vlan          = 100
    bgp_asn       = 65000
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.address_family == "ipv4"
    error_message = "address_family should default to ipv4."
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.mtu == 1500
    error_message = "mtu should default to 1500."
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.sitelink_enabled == false
    error_message = "sitelink_enabled should default to false."
  }

  # region is Optional and Computed on aws_dx_transit_virtual_interface (AWS provider v6's
  # per-resource Region override feature), so the mock provider generates fake data for it
  # when unset -- there is no meaningful "defaults to null" case to assert via mocks. The
  # override case in the "overrides_are_honored" run below is sufficient to prove the module
  # wires var.region through.

  assert {
    condition     = aws_dx_transit_virtual_interface.this.tags["Name"] == "example-transit-vif"
    error_message = "A Name tag should default to var.name."
  }

  assert {
    condition     = output.id == "dxvif-mock1234"
    error_message = "id output should expose the mocked virtual interface id."
  }

  assert {
    condition     = output.arn == "arn:aws:directconnect:us-east-1:123456789012:dxvif/dxvif-mock1234"
    error_message = "arn output should expose the mocked virtual interface ARN."
  }

  assert {
    condition     = output.amazon_side_asn == "64512"
    error_message = "amazon_side_asn output should expose the mocked value."
  }

  assert {
    condition     = output.jumbo_frame_capable == true
    error_message = "jumbo_frame_capable output should expose the mocked value."
  }
}

run "overrides_are_honored" {
  command = plan

  variables {
    connection_id    = "dxcon-example1"
    dx_gateway_id    = "abcd1234-dcba-5678-be23-cdef9876ab45"
    name             = "example-transit-vif"
    vlan             = 4094
    bgp_asn          = 65000
    address_family   = "ipv6"
    mtu              = 8500
    sitelink_enabled = true
    region           = "us-west-2"
    tags = {
      team = "networking"
    }
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.address_family == "ipv6"
    error_message = "address_family override should be honored."
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.mtu == 8500
    error_message = "mtu override should be honored."
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.sitelink_enabled == true
    error_message = "sitelink_enabled override should be honored."
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.region == "us-west-2"
    error_message = "region override should be passed through to aws_dx_transit_virtual_interface.this."
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.tags["team"] == "networking"
    error_message = "Caller-provided tags should be merged in."
  }
}

run "sensitive_bgp_auth_key_is_wired_through" {
  command = plan

  variables {
    connection_id    = "dxcon-example1"
    dx_gateway_id    = "abcd1234-dcba-5678-be23-cdef9876ab45"
    name             = "example-transit-vif"
    vlan             = 100
    bgp_asn          = 65000
    amazon_address   = "PLACEHOLDER-AMAZON-CIDR"
    customer_address = "PLACEHOLDER-CUSTOMER-CIDR"
    bgp_auth_key     = "PLACEHOLDER-NOT-A-REAL-SECRET"
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.amazon_address == "PLACEHOLDER-AMAZON-CIDR"
    error_message = "amazon_address override should be honored."
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.customer_address == "PLACEHOLDER-CUSTOMER-CIDR"
    error_message = "customer_address override should be honored."
  }

  assert {
    condition     = aws_dx_transit_virtual_interface.this.bgp_auth_key == "PLACEHOLDER-NOT-A-REAL-SECRET"
    error_message = "bgp_auth_key override should be honored."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
