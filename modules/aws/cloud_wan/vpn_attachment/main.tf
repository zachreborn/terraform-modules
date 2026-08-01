terraform {
  # >= 1.3.0 is required because variables.tf uses optional() object type attributes
  # (including the 2-arg optional(type, default) form in tunnel1/2_log_options), which
  # became a stable language feature in Terraform/OpenTofu 1.3.0. This also covers the
  # lifecycle.precondition blocks used below (stable since 1.2.0).
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # >= 6.27.0 is required because routing_policy_label on
      # aws_networkmanager_site_to_site_vpn_attachment was first released in AWS
      # provider v6.27.0 (https://github.com/hashicorp/terraform-provider-aws/issues/45194).
      version = ">= 6.27.0"
    }
  }
}

###########################
# Customer Gateway
###########################

resource "aws_customer_gateway" "this" {
  for_each         = var.customer_gateways
  bgp_asn          = try(each.value.bgp_asn, null)
  bgp_asn_extended = try(each.value.bgp_asn_extended, null)
  certificate_arn  = try(each.value.certificate_arn, null)
  device_name      = try(each.value.device_name, null)
  ip_address       = try(each.value.ip_address, null)
  type             = "ipsec.1"
  tags             = merge(tomap({ Name = each.key }), var.tags)
}

###########################
# Site-to-Site VPN Connection
###########################

resource "aws_vpn_connection" "this" {
  for_each            = var.customer_gateways
  customer_gateway_id = aws_customer_gateway.this[each.key].id
  static_routes_only  = var.static_routes_only
  type                = "ipsec.1"

  local_ipv4_network_cidr                 = var.local_ipv4_network_cidr
  local_ipv6_network_cidr                 = var.local_ipv6_network_cidr
  remote_ipv4_network_cidr                = var.remote_ipv4_network_cidr
  remote_ipv6_network_cidr                = var.remote_ipv6_network_cidr
  outside_ip_address_type                 = var.outside_ip_address_type
  transport_transit_gateway_attachment_id = var.transport_transit_gateway_attachment_id
  tunnel_bandwidth                        = var.tunnel_bandwidth
  tunnel_inside_ip_version                = var.tunnel_inside_ip_version

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
  tunnel1_inside_ipv6_cidr          = var.tunnel1_inside_ipv6_cidr
  tunnel2_inside_ipv6_cidr          = var.tunnel2_inside_ipv6_cidr
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

  tags = merge(tomap({ Name = "${each.key}-vpn" }), var.tags)

  lifecycle {
    precondition {
      condition     = var.outside_ip_address_type != "PrivateIpv4" || var.transport_transit_gateway_attachment_id != null
      error_message = "transport_transit_gateway_attachment_id must be set when outside_ip_address_type is PrivateIpv4."
    }
  }
}

###########################
# Cloud WAN Site-to-Site VPN Attachment
###########################

resource "aws_networkmanager_site_to_site_vpn_attachment" "this" {
  for_each             = var.create_cloud_wan_attachment ? var.customer_gateways : {}
  core_network_id      = var.core_network_id
  vpn_connection_arn   = aws_vpn_connection.this[each.key].arn
  routing_policy_label = var.routing_policy_label
  tags                 = merge(tomap({ Name = "${each.key}-cloud-wan-attachment" }), var.tags)

  lifecycle {
    precondition {
      condition     = var.core_network_id != null
      error_message = "core_network_id must be set when create_cloud_wan_attachment is true."
    }
  }
}
