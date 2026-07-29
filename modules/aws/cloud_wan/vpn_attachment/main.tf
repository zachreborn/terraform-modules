terraform {
  # >= 1.2.0 is required for the lifecycle.precondition block used below to validate
  # create_cloud_wan_attachment/core_network_id together.
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Customer Gateway
###########################

resource "aws_customer_gateway" "this" {
  count            = length(var.customer_gateways)
  bgp_asn          = try(var.customer_gateways[count.index].bgp_asn, null)
  bgp_asn_extended = try(var.customer_gateways[count.index].bgp_asn_extended, null)
  certificate_arn  = try(var.customer_gateways[count.index].certificate_arn, null)
  device_name      = try(var.customer_gateways[count.index].device_name, null)
  ip_address       = try(var.customer_gateways[count.index].ip_address, null)
  type             = "ipsec.1"
  tags             = merge(tomap({ Name = var.customer_gateways[count.index].name }), var.tags)
}

###########################
# Site-to-Site VPN Connection
###########################

resource "aws_vpn_connection" "this" {
  count               = length(var.customer_gateways)
  customer_gateway_id = aws_customer_gateway.this[count.index].id
  static_routes_only  = var.static_routes_only
  type                = "ipsec.1"

  local_ipv4_network_cidr                 = var.local_ipv4_network_cidr
  local_ipv6_network_cidr                 = var.local_ipv6_network_cidr
  remote_ipv4_network_cidr                = var.remote_ipv4_network_cidr
  remote_ipv6_network_cidr                = var.remote_ipv6_network_cidr
  outside_ip_address_type                 = var.outside_ip_address_type
  transport_transit_gateway_attachment_id = var.transport_transit_gateway_attachment_id

  tunnel1_ike_versions                 = var.tunnel_ike_versions
  tunnel2_ike_versions                 = var.tunnel_ike_versions
  tunnel1_phase1_dh_group_numbers      = var.tunnel_phase1_dh_group_numbers
  tunnel2_phase1_dh_group_numbers      = var.tunnel_phase1_dh_group_numbers
  tunnel1_phase1_encryption_algorithms = var.tunnel_phase1_encryption_algorithms
  tunnel2_phase1_encryption_algorithms = var.tunnel_phase1_encryption_algorithms
  tunnel1_phase1_integrity_algorithms  = var.tunnel_phase1_integrity_algorithms
  tunnel2_phase1_integrity_algorithms  = var.tunnel_phase1_integrity_algorithms
  tunnel1_phase2_dh_group_numbers      = var.tunnel_phase2_dh_group_numbers
  tunnel2_phase2_dh_group_numbers      = var.tunnel_phase2_dh_group_numbers
  tunnel1_phase2_encryption_algorithms = var.tunnel_phase2_encryption_algorithms
  tunnel2_phase2_encryption_algorithms = var.tunnel_phase2_encryption_algorithms
  tunnel1_phase2_integrity_algorithms  = var.tunnel_phase2_integrity_algorithms
  tunnel2_phase2_integrity_algorithms  = var.tunnel_phase2_integrity_algorithms
  tunnel1_startup_action               = var.tunnel_startup_action
  tunnel2_startup_action               = var.tunnel_startup_action

  tunnel1_preshared_key             = var.tunnel1_preshared_key
  tunnel2_preshared_key             = var.tunnel2_preshared_key
  tunnel1_inside_cidr               = var.tunnel1_inside_cidr
  tunnel2_inside_cidr               = var.tunnel2_inside_cidr
  tunnel1_dpd_timeout_action        = var.tunnel1_dpd_timeout_action
  tunnel2_dpd_timeout_action        = var.tunnel2_dpd_timeout_action
  tunnel1_dpd_timeout_seconds       = var.tunnel1_dpd_timeout_seconds
  tunnel2_dpd_timeout_seconds       = var.tunnel2_dpd_timeout_seconds
  tunnel1_phase1_lifetime_seconds   = var.tunnel1_phase1_lifetime_seconds
  tunnel2_phase1_lifetime_seconds   = var.tunnel2_phase1_lifetime_seconds
  tunnel1_phase2_lifetime_seconds   = var.tunnel1_phase2_lifetime_seconds
  tunnel2_phase2_lifetime_seconds   = var.tunnel2_phase2_lifetime_seconds
  tunnel1_rekey_margin_time_seconds = var.tunnel1_rekey_margin_time_seconds
  tunnel2_rekey_margin_time_seconds = var.tunnel2_rekey_margin_time_seconds
  tunnel1_rekey_fuzz_percentage     = var.tunnel1_rekey_fuzz_percentage # gitleaks:allow -- variable reference, not a literal secret
  tunnel2_rekey_fuzz_percentage     = var.tunnel2_rekey_fuzz_percentage # gitleaks:allow -- variable reference, not a literal secret
  tunnel1_replay_window_size        = var.tunnel1_replay_window_size
  tunnel2_replay_window_size        = var.tunnel2_replay_window_size

  dynamic "tunnel1_log_options" {
    for_each = var.tunnel1_log_options != null ? [var.tunnel1_log_options] : []
    content {
      dynamic "cloudwatch_log_options" {
        for_each = tunnel1_log_options.value.cloudwatch_log_options != null ? [tunnel1_log_options.value.cloudwatch_log_options] : []
        content {
          log_enabled       = cloudwatch_log_options.value.log_enabled
          log_group_arn     = cloudwatch_log_options.value.log_group_arn
          log_output_format = cloudwatch_log_options.value.log_output_format
        }
      }
    }
  }

  dynamic "tunnel2_log_options" {
    for_each = var.tunnel2_log_options != null ? [var.tunnel2_log_options] : []
    content {
      dynamic "cloudwatch_log_options" {
        for_each = tunnel2_log_options.value.cloudwatch_log_options != null ? [tunnel2_log_options.value.cloudwatch_log_options] : []
        content {
          log_enabled       = cloudwatch_log_options.value.log_enabled
          log_group_arn     = cloudwatch_log_options.value.log_group_arn
          log_output_format = cloudwatch_log_options.value.log_output_format
        }
      }
    }
  }

  tags = merge(tomap({ Name = "${var.customer_gateways[count.index].name}-vpn" }), var.tags)
}

###########################
# Cloud WAN Site-to-Site VPN Attachment
###########################

resource "aws_networkmanager_site_to_site_vpn_attachment" "this" {
  count                = var.create_cloud_wan_attachment ? length(var.customer_gateways) : 0
  core_network_id      = var.core_network_id
  vpn_connection_arn   = aws_vpn_connection.this[count.index].arn
  routing_policy_label = var.routing_policy_label
  tags                 = merge(tomap({ Name = "${var.customer_gateways[count.index].name}-cloud-wan-attachment" }), var.tags)

  lifecycle {
    precondition {
      condition     = var.core_network_id != null
      error_message = "core_network_id must be set when create_cloud_wan_attachment is true."
    }
  }
}
