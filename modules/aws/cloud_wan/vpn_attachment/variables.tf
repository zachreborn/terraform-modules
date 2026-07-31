###########################
# Customer Gateway Configuration
###########################

variable "customer_gateways" {
  type = map(object({
    ip_address       = optional(string)
    bgp_asn          = optional(number)
    bgp_asn_extended = optional(number)
    certificate_arn  = optional(string)
    device_name      = optional(string)
  }))
  description = "(Required) Map of customer gateway configurations keyed by logical gateway name. Each entry must specify either ip_address or certificate_arn for authentication, and may specify at most one of bgp_asn (1-2147483647) or bgp_asn_extended (2147483648-4294967295); if neither is set, AWS applies its default ASN of 65000."
  default     = {}
  validation {
    condition = alltrue([
      for gw in values(var.customer_gateways) :
      gw.ip_address == null || can(cidrhost("${gw.ip_address}/32", 0))
    ])
    error_message = "When set, customer gateway ip_address must be a valid IPv4 address."
  }
  validation {
    condition = alltrue([
      for gw in values(var.customer_gateways) :
      gw.ip_address != null || gw.certificate_arn != null
    ])
    error_message = "Each customer gateway must specify either ip_address or certificate_arn."
  }
  validation {
    condition = alltrue([
      for gw in values(var.customer_gateways) :
      !(gw.bgp_asn != null && gw.bgp_asn_extended != null)
    ])
    error_message = "Specify at most one of bgp_asn or bgp_asn_extended per customer gateway; they are mutually exclusive."
  }
}

###########################
# Cloud WAN Attachment Configuration
###########################

variable "create_cloud_wan_attachment" {
  type        = bool
  description = "(Optional) Whether to attach the created VPN connection(s) to a Cloud WAN core network via a Network Manager Site-to-Site VPN attachment. Defaults to false."
  default     = false
}

variable "core_network_id" {
  type        = string
  description = "(Required if create_cloud_wan_attachment is true) The ID of the Cloud WAN core network to attach the VPN connection(s) to."
  default     = null
}

variable "routing_policy_label" {
  type        = string
  description = "(Optional) The routing policy label to apply to the Site-to-Site VPN attachment(s) for traffic routing decisions. Maximum length of 256 characters. Changing this value forces recreation of the attachment."
  default     = null
}

###########################
# VPN Connection Configuration
###########################

variable "static_routes_only" {
  type        = bool
  description = "(Optional) Whether the VPN connection uses static routes exclusively. Defaults to true."
  default     = true
}

variable "tunnel_ike_versions" {
  type        = list(string)
  description = "(Optional) The IKE versions that are permitted for the VPN tunnels. Valid values are ikev1 | ikev2."
  default     = ["ikev2"]
  validation {
    condition = alltrue([
      for version in var.tunnel_ike_versions :
      can(index(["ikev1", "ikev2"], version))
    ])
    error_message = "tunnel_ike_versions must contain only ikev1 or ikev2."
  }
}

variable "tunnel_phase1_dh_group_numbers" {
  type        = list(string)
  description = "(Optional) DH group numbers for Phase 1. Valid values are 2, 14-24."
  default     = ["14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24"]
}

variable "tunnel_phase1_encryption_algorithms" {
  type        = list(string)
  description = "(Optional) Encryption algorithms for Phase 1. Valid values are AES128, AES256, AES128-GCM-16, AES256-GCM-16."
  default     = ["AES256", "AES256-GCM-16"]
}

variable "tunnel_phase1_integrity_algorithms" {
  type        = list(string)
  description = "(Optional) Integrity algorithms for Phase 1. Valid values are SHA1, SHA2-256, SHA2-384, SHA2-512."
  default     = ["SHA2-256", "SHA2-384", "SHA2-512"]
}

variable "tunnel_phase2_dh_group_numbers" {
  type        = list(string)
  description = "(Optional) DH group numbers for Phase 2. Valid values are 2, 5, 14-24."
  default     = ["14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24"]
}

variable "tunnel_phase2_encryption_algorithms" {
  type        = list(string)
  description = "(Optional) Encryption algorithms for Phase 2. Valid values are AES128, AES256, AES128-GCM-16, AES256-GCM-16."
  default     = ["AES256", "AES256-GCM-16"]
}

variable "tunnel_phase2_integrity_algorithms" {
  type        = list(string)
  description = "(Optional) Integrity algorithms for Phase 2. Valid values are SHA1, SHA2-256, SHA2-384, SHA2-512."
  default     = ["SHA2-256", "SHA2-384", "SHA2-512"]
}

variable "tunnel_startup_action" {
  type        = string
  description = "(Optional) Action to take when establishing the tunnel. Valid values are add | start. Defaults to add."
  default     = "add"
  validation {
    condition     = can(index(["add", "start"], var.tunnel_startup_action))
    error_message = "tunnel_startup_action must be add or start."
  }
}

variable "tunnel_bandwidth" {
  type        = string
  description = "(Optional) Desired bandwidth specification for the VPN tunnel(s). Valid values are standard | large. standard supports up to 1.25 Gbps per tunnel; large supports up to 5 Gbps per tunnel. Defaults to standard."
  default     = "standard"
  validation {
    condition     = can(index(["standard", "large"], var.tunnel_bandwidth))
    error_message = "tunnel_bandwidth must be standard or large."
  }
}

variable "tunnel_inside_ip_version" {
  type        = string
  description = "(Optional) Whether the VPN tunnel(s) process IPv4 or IPv6 traffic. Valid values are ipv4 | ipv6. ipv6 requires the VPN connection to also be attached to an EC2 Transit Gateway (managed outside of this module). Defaults to ipv4."
  default     = "ipv4"
  validation {
    condition     = can(index(["ipv4", "ipv6"], var.tunnel_inside_ip_version))
    error_message = "tunnel_inside_ip_version must be ipv4 or ipv6."
  }
}

variable "local_ipv4_network_cidr" {
  type        = string
  description = "(Optional) The IPv4 CIDR on the customer gateway (on-premises) side of the VPN connection(s). Defaults to the wildcard IPv4 CIDR (all addresses) when unset."
  default     = null
}

variable "local_ipv6_network_cidr" {
  type        = string
  description = "(Optional) The IPv6 CIDR on the customer gateway (on-premises) side of the VPN connection(s). Defaults to ::/0 when unset."
  default     = null
}

variable "remote_ipv4_network_cidr" {
  type        = string
  description = "(Optional) The IPv4 CIDR on the AWS side of the VPN connection(s). Defaults to the wildcard IPv4 CIDR (all addresses) when unset."
  default     = null
}

variable "remote_ipv6_network_cidr" {
  type        = string
  description = "(Optional) The IPv6 CIDR on the AWS side of the VPN connection(s). Defaults to ::/0 when unset."
  default     = null
}

variable "outside_ip_address_type" {
  type        = string
  description = "(Optional) Indicates a Public or Private (over Direct Connect) Site-to-Site VPN. Valid values are PublicIpv4 | PrivateIpv4. Defaults to PublicIpv4 when unset. PrivateIpv4 requires transport_transit_gateway_attachment_id and an EC2 Transit Gateway attachment managed outside of this module."
  default     = null
  validation {
    condition     = var.outside_ip_address_type == null || can(index(["PublicIpv4", "PrivateIpv4"], var.outside_ip_address_type))
    error_message = "outside_ip_address_type must be PublicIpv4 or PrivateIpv4."
  }
}

variable "transport_transit_gateway_attachment_id" {
  type        = string
  description = "(Optional) The attachment ID of the Transit Gateway attachment to a Direct Connect Gateway. Required when outside_ip_address_type is PrivateIpv4. Obtained from the aws_ec2_transit_gateway_dx_gateway_attachment data source."
  default     = null
}

variable "tunnel1_preshared_key" {
  type        = string
  description = "(Optional) The preshared key of the first VPN tunnel, applied to every VPN connection created by this module. Must be 8-64 characters and cannot start with 0. If omitted, AWS generates one automatically."
  default     = null
  sensitive   = true
}

variable "tunnel2_preshared_key" {
  type        = string
  description = "(Optional) The preshared key of the second VPN tunnel, applied to every VPN connection created by this module. Must be 8-64 characters and cannot start with 0. If omitted, AWS generates one automatically."
  default     = null
  sensitive   = true
}

variable "tunnel1_inside_cidr" {
  type        = string
  description = "(Optional) The CIDR block of the inside IP addresses for the first VPN tunnel. Must be a /30 from the AWS-reserved link-local range for VPN tunnels (169 dot 254 dot 0 dot 0 slash 16)."
  default     = null
}

variable "tunnel2_inside_cidr" {
  type        = string
  description = "(Optional) The CIDR block of the inside IP addresses for the second VPN tunnel. Must be a /30 from the AWS-reserved link-local range for VPN tunnels (169 dot 254 dot 0 dot 0 slash 16)."
  default     = null
}

variable "tunnel1_inside_ipv6_cidr" {
  type        = string
  description = "(Optional) The range of inside IPv6 addresses for the first VPN tunnel. Only applicable when tunnel_inside_ip_version is ipv6 and the VPN connection is also attached to an EC2 Transit Gateway (managed outside of this module). Must be a /126 from the local fd00::/8 range."
  default     = null
}

variable "tunnel2_inside_ipv6_cidr" {
  type        = string
  description = "(Optional) The range of inside IPv6 addresses for the second VPN tunnel. Only applicable when tunnel_inside_ip_version is ipv6 and the VPN connection is also attached to an EC2 Transit Gateway (managed outside of this module). Must be a /126 from the local fd00::/8 range."
  default     = null
}

variable "tunnel1_dpd_timeout_action" {
  type        = string
  description = "(Optional) Action to take after a DPD timeout occurs for the first tunnel. Valid values are clear | none | restart. Defaults to clear."
  default     = "clear"
  validation {
    condition     = can(index(["clear", "none", "restart"], var.tunnel1_dpd_timeout_action))
    error_message = "tunnel1_dpd_timeout_action must be clear, none, or restart."
  }
}

variable "tunnel2_dpd_timeout_action" {
  type        = string
  description = "(Optional) Action to take after a DPD timeout occurs for the second tunnel. Valid values are clear | none | restart. Defaults to clear."
  default     = "clear"
  validation {
    condition     = can(index(["clear", "none", "restart"], var.tunnel2_dpd_timeout_action))
    error_message = "tunnel2_dpd_timeout_action must be clear, none, or restart."
  }
}

variable "tunnel1_dpd_timeout_seconds" {
  type        = number
  description = "(Optional) Number of seconds after which a DPD timeout occurs for the first tunnel. Must be 30 or higher. Defaults to 30."
  default     = 30
}

variable "tunnel2_dpd_timeout_seconds" {
  type        = number
  description = "(Optional) Number of seconds after which a DPD timeout occurs for the second tunnel. Must be 30 or higher. Defaults to 30."
  default     = 30
}

variable "tunnel1_phase1_lifetime_seconds" {
  type        = number
  description = "(Optional) Lifetime for phase 1 of the IKE negotiation for the first tunnel, in seconds. Valid range is 900-28800. Defaults to 28800."
  default     = 28800
}

variable "tunnel2_phase1_lifetime_seconds" {
  type        = number
  description = "(Optional) Lifetime for phase 1 of the IKE negotiation for the second tunnel, in seconds. Valid range is 900-28800. Defaults to 28800."
  default     = 28800
}

variable "tunnel1_phase2_lifetime_seconds" {
  type        = number
  description = "(Optional) Lifetime for phase 2 of the IKE negotiation for the first tunnel, in seconds. Valid range is 900-3600. Defaults to 3600."
  default     = 3600
}

variable "tunnel2_phase2_lifetime_seconds" {
  type        = number
  description = "(Optional) Lifetime for phase 2 of the IKE negotiation for the second tunnel, in seconds. Valid range is 900-3600. Defaults to 3600."
  default     = 3600
}

variable "tunnel1_rekey_margin_time_seconds" {
  type        = number
  description = "(Optional) Margin time, in seconds, before the phase 2 lifetime expires for the first tunnel, during which AWS performs an IKE rekey. Defaults to 540."
  default     = 540
}

variable "tunnel2_rekey_margin_time_seconds" {
  type        = number
  description = "(Optional) Margin time, in seconds, before the phase 2 lifetime expires for the second tunnel, during which AWS performs an IKE rekey. Defaults to 540."
  default     = 540
}

variable "tunnel1_rekey_fuzz_percentage" {
  type        = number
  description = "(Optional) Percentage of the rekey window for the first tunnel during which the rekey time is randomly selected. Defaults to 100."
  default     = 100
}

variable "tunnel2_rekey_fuzz_percentage" {
  type        = number
  description = "(Optional) Percentage of the rekey window for the second tunnel during which the rekey time is randomly selected. Defaults to 100."
  default     = 100
}

variable "tunnel1_replay_window_size" {
  type        = number
  description = "(Optional) Number of packets in an IKE replay window for the first tunnel. Valid range is 64-2048. Defaults to 1024."
  default     = 1024
}

variable "tunnel2_replay_window_size" {
  type        = number
  description = "(Optional) Number of packets in an IKE replay window for the second tunnel. Valid range is 64-2048. Defaults to 1024."
  default     = 1024
}

variable "tunnel1_log_options" {
  type = object({
    cloudwatch_log_options = optional(object({
      log_enabled       = optional(bool, false)
      log_group_arn     = optional(string)
      log_output_format = optional(string)
    }))
  })
  description = "(Optional) Options for logging first VPN tunnel activity to CloudWatch Logs."
  default     = null
}

variable "tunnel2_log_options" {
  type = object({
    cloudwatch_log_options = optional(object({
      log_enabled       = optional(bool, false)
      log_group_arn     = optional(string)
      log_output_format = optional(string)
    }))
  })
  description = "(Optional) Options for logging second VPN tunnel activity to CloudWatch Logs."
  default     = null
}

###########################
# General
###########################

variable "tags" {
  type        = map(any)
  description = "(Optional) A map of tags to assign to the resources."
  default = {
    created_by = "terraform"
    terraform  = "true"
  }
}
