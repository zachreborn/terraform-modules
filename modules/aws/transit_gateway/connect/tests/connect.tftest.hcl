mock_provider "aws" {}

run "baseline_attachment_with_no_peers" {
  command = plan

  variables {
    name                    = "sdwan-connect"
    transport_attachment_id = "tgw-attach-0123456789abcdef0"
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peers                   = {}
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect.connect_attachment.protocol == "gre"
    error_message = "protocol should default to gre."
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect.connect_attachment.transport_attachment_id == "tgw-attach-0123456789abcdef0"
    error_message = "transport_attachment_id should pass through unchanged."
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect.connect_attachment.tags["Name"] == "sdwan-connect"
    error_message = "Name tag should default to the name variable."
  }

  assert {
    condition     = output.attachment_id != null
    error_message = "attachment_id output should be set."
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_connect_peer.peer) == 0
    error_message = "No connect peers should be planned when peers is empty."
  }
}

run "connect_peer_defaults_are_applied" {
  command = plan

  variables {
    name                    = "sdwan-connect"
    transport_attachment_id = "tgw-attach-0123456789abcdef0"
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peers = {
      sdwan_vedge_1 = {
        inside_cidr_blocks = ["169.254.6.0/29"]
        peer_address       = "203.0.113.11"
      }
    }
  }

  # transit_gateway_address is Optional+Computed on the underlying resource and
  # is left unset in the peers input above. Give it a distinctive sentinel via
  # override_resource (which only takes effect for attributes that are still
  # null/computed in this run's plan) and assert that exact sentinel. If a
  # module regression hard-coded any address for transit_gateway_address
  # instead of passing each.value.transit_gateway_address through, the
  # attribute would no longer be eligible for this override and the assertion
  # below would fail.
  override_resource {
    target = aws_ec2_transit_gateway_connect_peer.peer
    values = {
      transit_gateway_address = "203.0.113.55"
    }
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_connect_peer.peer) == 1
    error_message = "Expected exactly one connect peer to be planned."
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect_peer.peer["sdwan_vedge_1"].bgp_asn == "64512"
    error_message = "bgp_asn should default to 64512."
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect_peer.peer["sdwan_vedge_1"].transit_gateway_address == "203.0.113.55"
    error_message = "transit_gateway_address should reflect the provider-assigned (overridden) sentinel, proving the module left it unset rather than coercing it to a fixed value."
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect_peer.peer["sdwan_vedge_1"].tags["Name"] == "sdwan_vedge_1"
    error_message = "Connect peer Name tag should default to its map key."
  }

  assert {
    condition     = output.transit_gateway_addresses["sdwan_vedge_1"] == "203.0.113.55"
    error_message = "transit_gateway_addresses output should reflect the provider-assigned (overridden) sentinel."
  }
}

run "connect_peer_overrides_are_honored" {
  command = plan

  variables {
    name                    = "sdwan-connect"
    transport_attachment_id = "tgw-attach-0123456789abcdef0"
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peers = {
      sdwan_vedge_1 = {
        bgp_asn                 = 64513
        inside_cidr_blocks      = ["169.254.6.0/29"]
        peer_address            = "203.0.113.11"
        transit_gateway_address = "169.254.6.1"
      }
    }
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect_peer.peer["sdwan_vedge_1"].bgp_asn == "64513"
    error_message = "bgp_asn override should be honored."
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect_peer.peer["sdwan_vedge_1"].transit_gateway_address == "169.254.6.1"
    error_message = "transit_gateway_address override should be honored."
  }
}

run "multiple_connect_peers_expand_via_for_each" {
  command = plan

  variables {
    name                    = "sdwan-connect"
    transport_attachment_id = "tgw-attach-0123456789abcdef0"
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peers = {
      sdwan_vedge_1 = {
        inside_cidr_blocks = ["169.254.6.0/29"]
        peer_address       = "203.0.113.11"
      }
      sdwan_vedge_2 = {
        inside_cidr_blocks = ["169.254.7.0/29"]
        peer_address       = "203.0.113.12"
      }
    }
  }

  assert {
    condition     = length(aws_ec2_transit_gateway_connect_peer.peer) == 2
    error_message = "Expected one connect peer resource per map entry."
  }

  assert {
    condition     = length(output.arns) == 2
    error_message = "arns output should contain one entry per connect peer."
  }

  assert {
    condition     = length(output.configurations) == 2
    error_message = "configurations output should contain one entry per connect peer."
  }

  assert {
    condition     = output.configurations["sdwan_vedge_1"].bgp_asn == "64512"
    error_message = "configurations output's bgp_asn field should reflect the connect peer's actual bgp_asn."
  }

  assert {
    condition     = output.configurations["sdwan_vedge_1"].id == aws_ec2_transit_gateway_connect_peer.peer["sdwan_vedge_1"].id
    error_message = "configurations output's id field should match the connect peer resource's id."
  }

  assert {
    condition     = output.configurations["sdwan_vedge_1"].peer_address == var.peers["sdwan_vedge_1"].peer_address
    error_message = "configurations output's peer_address field should match the configured peer_address."
  }

  # NOTE: the configurations output's CIDR-block field is currently named
  # insider_cidr_blocks (a typo -- it should be inside_cidr_blocks). That is
  # fixed in the separate fix PR #409 (out of scope for this test-only PR
  # since it requires editing outputs.tf), which also adds inside_cidr_blocks
  # as the corrected key while keeping this one as a deprecated alias.
  assert {
    condition     = length(output.configurations["sdwan_vedge_1"].insider_cidr_blocks) == 1
    error_message = "configurations output should expose exactly one CIDR block for this peer under its current (typo'd) key name."
  }

  assert {
    condition     = output.peer_addresses["sdwan_vedge_1"] == var.peers["sdwan_vedge_1"].peer_address
    error_message = "peer_addresses output should map each peer to its configured address."
  }

  assert {
    condition     = output.peer_addresses["sdwan_vedge_2"] == var.peers["sdwan_vedge_2"].peer_address
    error_message = "peer_addresses output should map each peer to its configured address."
  }
}

run "outputs_expose_ids_and_bgp_asns" {
  command = plan

  variables {
    name                    = "sdwan-connect"
    transport_attachment_id = "tgw-attach-0123456789abcdef0"
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peers = {
      sdwan_vedge_1 = {
        inside_cidr_blocks = ["169.254.6.0/29"]
        peer_address       = "203.0.113.11"
      }
    }
  }

  assert {
    condition     = output.ids["sdwan_vedge_1"] != null
    error_message = "ids output should expose the connect peer's ID."
  }

  assert {
    condition     = output.bgp_asns["sdwan_vedge_1"] == "64512"
    error_message = "bgp_asns output should expose the peer's BGP ASN."
  }

  assert {
    condition     = length(output.inside_cidr_blocks["sdwan_vedge_1"]) == 1
    error_message = "inside_cidr_blocks output should expose exactly one CIDR block for this peer."
  }
}
