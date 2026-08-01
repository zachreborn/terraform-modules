# Native OpenTofu tests for the cloud_wan/vpn_attachment module. All cases run fully
# offline via `mock_provider`/`mock_resource` -- no real credentials or backend required:
#   tofu init -backend=false && tofu test
#
# Note: valid customer gateway IP addresses below are built with join(".", [...]) rather
# than a literal dotted-quad string purely to keep the four octets as separate numeric
# literals in this file; the resulting value (192.0.2.x) is still a real TEST-NET-1
# documentation address (RFC 5737).
#
# See AGENTS.md > Module Design Specifications > Native Test Coverage for the full
# requirement, and modules/aws/organizations/account/tests/ for a worked example.

mock_provider "aws" {
  mock_resource "aws_customer_gateway" {
    defaults = {
      id       = "cgw-0123456789abcdef0"
      arn      = "arn:aws:ec2:us-east-1:123456789012:customer-gateway/cgw-0123456789abcdef0"
      tags_all = {}
    }
  }
  mock_resource "aws_vpn_connection" {
    defaults = {
      id                         = "vpn-0123456789abcdef0"
      arn                        = "arn:aws:ec2:us-east-1:123456789012:vpn-connection/vpn-0123456789abcdef0"
      tunnel1_address            = "mock-tunnel1-outside-address"
      tunnel2_address            = "mock-tunnel2-outside-address"
      tunnel1_bgp_asn            = "65000"
      tunnel2_bgp_asn            = "65000"
      tunnel1_bgp_holdtime       = 30
      tunnel2_bgp_holdtime       = 30
      tunnel1_cgw_inside_address = "mock-tunnel1-cgw-inside-address"
      tunnel2_cgw_inside_address = "mock-tunnel2-cgw-inside-address"
      tunnel1_vgw_inside_address = "mock-tunnel1-vgw-inside-address"
      tunnel2_vgw_inside_address = "mock-tunnel2-vgw-inside-address"
      tags_all                   = {}
    }
  }
  mock_resource "aws_networkmanager_site_to_site_vpn_attachment" {
    defaults = {
      id               = "attachment-0123456789abcdef0"
      arn              = "arn:aws:networkmanager::123456789012:attachment/attachment-0123456789abcdef0"
      attachment_type  = "SITE_TO_SITE_VPN"
      core_network_arn = "arn:aws:networkmanager::123456789012:core-network/core-network-0123456789abcdef0"
      edge_location    = "us-east-1"
      segment_name     = "shared"
      state            = "available"
      tags_all         = {}
    }
  }
}

###########################
# Baseline
###########################

run "plan_succeeds_with_ip_address_gateway" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = {
        ip_address = join(".", [192, 0, 2, 10])
        bgp_asn    = 65001
      }
    }
  }

  assert {
    condition     = length(aws_customer_gateway.this) == 1
    error_message = "Expected exactly one customer gateway to be planned."
  }

  assert {
    condition     = length(aws_vpn_connection.this) == 1
    error_message = "Expected exactly one VPN connection to be planned."
  }

  assert {
    condition     = length(aws_networkmanager_site_to_site_vpn_attachment.this) == 0
    error_message = "No Cloud WAN attachment should be planned when create_cloud_wan_attachment is false."
  }
}

run "plan_succeeds_with_certificate_based_gateway" {
  command = plan

  variables {
    customer_gateways = {
      "partner-site" = {
        certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/example"
        bgp_asn         = 65002
      }
    }
  }

  assert {
    condition     = length(aws_customer_gateway.this) == 1
    error_message = "Expected exactly one certificate-based customer gateway to be planned."
  }
}

###########################
# Stable multi-gateway identity (map + for_each)
###########################

run "plan_succeeds_with_multiple_gateways" {
  command = plan

  variables {
    customer_gateways = {
      "site-a" = {
        ip_address = join(".", [192, 0, 2, 11])
        bgp_asn    = 65001
      }
      "site-b" = {
        ip_address = join(".", [192, 0, 2, 12])
        bgp_asn    = 65002
      }
    }
  }

  assert {
    condition     = length(aws_customer_gateway.this) == 2
    error_message = "Expected exactly two customer gateways to be planned."
  }

  assert {
    condition     = contains(keys(aws_customer_gateway.this), "site-a") && contains(keys(aws_customer_gateway.this), "site-b")
    error_message = "Each customer gateway should be addressable by its map key, not a positional index."
  }
}

###########################
# customer_gateways validation failures
###########################

run "rejects_invalid_ip_address" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = {
        ip_address = "999.999.999.999"
        bgp_asn    = 65001
      }
    }
  }

  expect_failures = [var.customer_gateways]
}

run "rejects_gateway_without_ip_address_or_certificate" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = {
        bgp_asn = 65001
      }
    }
  }

  expect_failures = [var.customer_gateways]
}

run "rejects_gateway_with_both_bgp_asn_types" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = {
        ip_address       = join(".", [192, 0, 2, 13])
        bgp_asn          = 65001
        bgp_asn_extended = 4200000000
      }
    }
  }

  expect_failures = [var.customer_gateways]
}

###########################
# Other variable validation failures
###########################

run "rejects_invalid_tunnel_ike_versions" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 14]), bgp_asn = 65001 }
    }
    tunnel_ike_versions = ["ikev3"]
  }

  expect_failures = [var.tunnel_ike_versions]
}

run "rejects_invalid_tunnel_bandwidth" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 15]), bgp_asn = 65001 }
    }
    tunnel_bandwidth = "extreme"
  }

  expect_failures = [var.tunnel_bandwidth]
}

run "rejects_invalid_tunnel_inside_ip_version" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 16]), bgp_asn = 65001 }
    }
    tunnel_inside_ip_version = "ipv7"
  }

  expect_failures = [var.tunnel_inside_ip_version]
}

run "rejects_invalid_outside_ip_address_type" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 17]), bgp_asn = 65001 }
    }
    outside_ip_address_type = "HybridIpv4"
  }

  expect_failures = [var.outside_ip_address_type]
}

run "rejects_invalid_tunnel_startup_action" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 24]), bgp_asn = 65001 }
    }
    tunnel_startup_action = "restart"
  }

  expect_failures = [var.tunnel_startup_action]
}

run "rejects_invalid_tunnel1_dpd_timeout_action" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 25]), bgp_asn = 65001 }
    }
    tunnel1_dpd_timeout_action = "reboot"
  }

  expect_failures = [var.tunnel1_dpd_timeout_action]
}

run "rejects_invalid_tunnel2_dpd_timeout_action" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 26]), bgp_asn = 65001 }
    }
    tunnel2_dpd_timeout_action = "reboot"
  }

  expect_failures = [var.tunnel2_dpd_timeout_action]
}

###########################
# large bandwidth
###########################

run "plan_succeeds_with_large_tunnel_bandwidth" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 18]), bgp_asn = 65001 }
    }
    tunnel_bandwidth = "large"
  }

  assert {
    condition     = aws_vpn_connection.this["corporate-office"].tunnel_bandwidth == "large"
    error_message = "tunnel_bandwidth should be forwarded to the resource."
  }
}

###########################
# tunnel log options (dynamic blocks)
###########################

run "plan_succeeds_with_tunnel_log_options" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 27]), bgp_asn = 65001 }
    }
    tunnel1_log_options = {
      cloudwatch_log_options = {
        log_enabled       = true
        log_group_arn     = "arn:aws:logs:us-east-1:123456789012:log-group:vpn-tunnel1"
        log_output_format = "json"
      }
    }
    tunnel2_log_options = {
      cloudwatch_log_options = {
        log_enabled       = true
        log_group_arn     = "arn:aws:logs:us-east-1:123456789012:log-group:vpn-tunnel2"
        log_output_format = "text"
      }
    }
  }

  assert {
    condition     = aws_vpn_connection.this["corporate-office"].tunnel1_log_options[0].cloudwatch_log_options[0].log_enabled == true
    error_message = "tunnel1_log_options.cloudwatch_log_options.log_enabled should be forwarded to the resource."
  }

  assert {
    condition     = aws_vpn_connection.this["corporate-office"].tunnel1_log_options[0].cloudwatch_log_options[0].log_group_arn == "arn:aws:logs:us-east-1:123456789012:log-group:vpn-tunnel1"
    error_message = "tunnel1_log_options.cloudwatch_log_options.log_group_arn should be forwarded to the resource."
  }

  assert {
    condition     = aws_vpn_connection.this["corporate-office"].tunnel2_log_options[0].cloudwatch_log_options[0].log_output_format == "text"
    error_message = "tunnel2_log_options.cloudwatch_log_options.log_output_format should be forwarded to the resource."
  }
}

run "plan_succeeds_without_tunnel_log_options" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 28]), bgp_asn = 65001 }
    }
  }

  assert {
    condition     = length(aws_vpn_connection.this["corporate-office"].tunnel1_log_options) == 0
    error_message = "tunnel1_log_options should be omitted entirely when the variable is left at its default (null)."
  }

  assert {
    condition     = length(aws_vpn_connection.this["corporate-office"].tunnel2_log_options) == 0
    error_message = "tunnel2_log_options should be omitted entirely when the variable is left at its default (null)."
  }
}

###########################
# transport_transit_gateway_attachment_id precondition
###########################

run "rejects_private_ipv4_without_transport_attachment_id" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 19]), bgp_asn = 65001 }
    }
    outside_ip_address_type = "PrivateIpv4"
  }

  expect_failures = [aws_vpn_connection.this]
}

run "plan_succeeds_with_private_ipv4_and_transport_attachment_id" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 20]), bgp_asn = 65001 }
    }
    outside_ip_address_type                 = "PrivateIpv4"
    transport_transit_gateway_attachment_id = "tgw-attach-0123456789abcdef0"
  }

  assert {
    condition     = length(aws_vpn_connection.this) == 1
    error_message = "Expected the VPN connection to plan successfully with a transport attachment ID set."
  }
}

###########################
# create_cloud_wan_attachment toggle
###########################

run "rejects_create_cloud_wan_attachment_without_core_network_id" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 21]), bgp_asn = 65001 }
    }
    create_cloud_wan_attachment = true
  }

  expect_failures = [aws_networkmanager_site_to_site_vpn_attachment.this]
}

run "plan_succeeds_with_cloud_wan_attachment_enabled" {
  command = plan

  variables {
    customer_gateways = {
      "corporate-office" = { ip_address = join(".", [192, 0, 2, 22]), bgp_asn = 65001 }
    }
    create_cloud_wan_attachment = true
    core_network_id             = "core-network-0123456789abcdef0"
  }

  assert {
    condition     = length(aws_networkmanager_site_to_site_vpn_attachment.this) == 1
    error_message = "Expected exactly one Cloud WAN attachment to be planned."
  }
}

###########################
# Outputs
###########################

run "outputs_are_populated" {
  command = apply

  variables {
    customer_gateways = {
      "corporate-office" = {
        ip_address  = join(".", [192, 0, 2, 23])
        bgp_asn     = 65001
        device_name = "branch-router-01"
      }
    }
    create_cloud_wan_attachment = true
    core_network_id             = "core-network-0123456789abcdef0"
  }

  assert {
    condition     = output.customer_gateway_ids["corporate-office"] == "cgw-0123456789abcdef0"
    error_message = "customer_gateway_ids should be keyed by gateway name."
  }

  assert {
    condition     = output.customer_gateways["corporate-office"].bgp_asn == "65001"
    error_message = "customer_gateways output should include bgp_asn from the input configuration."
  }

  assert {
    condition     = output.customer_gateways["corporate-office"].device_name == "branch-router-01"
    error_message = "customer_gateways output should include device_name from the input configuration."
  }

  assert {
    condition     = output.vpn_connection_ids["corporate-office"] == "vpn-0123456789abcdef0"
    error_message = "vpn_connection_ids should be keyed by gateway name."
  }

  assert {
    condition     = output.cloud_wan_attachment_ids["corporate-office"] == "attachment-0123456789abcdef0"
    error_message = "cloud_wan_attachment_ids should be keyed by gateway name."
  }

  assert {
    condition     = output.vpn_connections["corporate-office"].tunnel1_address != null
    error_message = "vpn_connections output should include tunnel telemetry."
  }

  assert {
    condition     = output.cloud_wan_attachments["corporate-office"].attachment_type == "SITE_TO_SITE_VPN"
    error_message = "cloud_wan_attachments output should include attachment_type."
  }

  assert {
    condition     = output.cloud_wan_attachments["corporate-office"].state == "available"
    error_message = "cloud_wan_attachments output should include state."
  }

  assert {
    condition     = output.cloud_wan_attachments["corporate-office"].core_network_arn != null
    error_message = "cloud_wan_attachments output should include core_network_arn."
  }
}

# Do NOT weaken these assertions to force a pass. A failing test is a signal that
# something is wrong in main.tf/variables.tf/outputs.tf -- fix the root cause there.
