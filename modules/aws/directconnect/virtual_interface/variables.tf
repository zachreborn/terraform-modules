###########################
# Transit Virtual Interface
###########################

variable "connection_id" {
  description = "(Required) The ID of the Direct Connect connection (or LAG) on which to create the virtual interface."
  type        = string
}

variable "dx_gateway_id" {
  description = "(Required) The ID of the Direct Connect gateway to which to connect the virtual interface."
  type        = string
}

variable "name" {
  description = "(Required) The name of the virtual interface."
  type        = string
}

variable "vlan" {
  description = "(Required) The VLAN ID. Must match the VLAN configured on the physical connection with the carrier."
  type        = number
  validation {
    condition     = var.vlan >= 1 && var.vlan <= 4094
    error_message = "vlan must be between 1 and 4094."
  }
}

variable "address_family" {
  description = "(Required) The address family for the BGP peer. Valid values: ipv4, ipv6."
  type        = string
  default     = "ipv4"
  validation {
    condition     = contains(["ipv4", "ipv6"], var.address_family)
    error_message = "address_family must be ipv4 or ipv6."
  }
}

variable "bgp_asn" {
  description = "(Required) The customer-side autonomous system (AS) number for BGP configuration."
  type        = number
}

variable "amazon_address" {
  description = "(Optional) The IPv4 CIDR address to use for the Amazon side of the BGP session (e.g. 169.254.96.9/29). Required when address_family is ipv4."
  type        = string
  default     = null
}

variable "customer_address" {
  description = "(Optional) The IPv4 CIDR address to use for the customer side of the BGP session (e.g. 169.254.96.14/29). Required when address_family is ipv4."
  type        = string
  default     = null
}

variable "bgp_auth_key" {
  description = "(Optional) The MD5 authentication key for the BGP session. Store as a sensitive workspace variable."
  type        = string
  default     = null
  sensitive   = true
}

variable "mtu" {
  description = "(Optional) The maximum transmission unit (MTU) in bytes. Valid values: 1500 (default) or 8500 (jumbo frames). Set to 8500 for Cloud WAN / Transit Gateway connectivity."
  type        = number
  default     = 1500
  validation {
    condition     = contains([1500, 8500], var.mtu)
    error_message = "mtu must be 1500 or 8500."
  }
}

variable "sitelink_enabled" {
  description = "(Optional) Whether to enable SiteLink on the virtual interface. SiteLink allows direct connectivity between Direct Connect locations."
  type        = bool
  default     = false
}

###########################
# Tags
###########################

variable "tags" {
  description = "(Optional) Map of tags to assign to the virtual interface. A Name tag is automatically added from var.name."
  type        = map(string)
  default     = {}
}
