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

  assert {
    condition     = length(aws_ec2_transit_gateway_connect_peer.peer) == 1
    error_message = "Expected exactly one connect peer to be planned."
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect_peer.peer["sdwan_vedge_1"].bgp_asn == "64512"
    error_message = "bgp_asn should default to 64512."
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect_peer.peer["sdwan_vedge_1"].transit_gateway_address != null
    error_message = "transit_gateway_address is Optional+Computed on the underlying resource -- when not set explicitly it should be left for AWS/the provider to assign, not coerced to a fixed value."
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect_peer.peer["sdwan_vedge_1"].tags["Name"] == "sdwan_vedge_1"
    error_message = "Connect peer Name tag should default to its map key."
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
    condition     = output.peer_addresses["sdwan_vedge_1"] == "203.0.113.11"
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
