###########################
# VIF Configuration
###########################

variable "dx_connection_id" {
  type        = string
  description = "(Required) The ID of the Direct Connect connection."
}

variable "vif_type" {
  type        = string
  description = "(Required) The type of the virtual interface. Valid values are private, public, transit."
  validation {
    condition     = can(index(["private", "public", "transit"], var.vif_type))
    error_message = "vif_type must be one of: private, public, transit."
  }
}

variable "vif_name" {
  type        = string
  description = "(Required) The name of the virtual interface."
}

variable "vlan" {
  type        = number
  description = "(Required) The VLAN ID for the VIF. Valid values are 1-4094."
  validation {
    condition     = var.vlan >= 1 && var.vlan <= 4094
    error_message = "vlan must be between 1 and 4094."
  }
}

variable "customer_bgp_asn" {
  type        = number
  description = "(Required) The ASN used by the customer on the customer side of the connection."
}

variable "address_family" {
  type        = string
  description = "(Optional) The address family for the BGP peer. ipv4 or ipv6. Defaults to ipv4."
  default     = "ipv4"
  validation {
    condition     = can(index(["ipv4", "ipv6"], var.address_family))
    error_message = "address_family must be ipv4 or ipv6."
  }
}

variable "customer_address" {
  type        = string
  description = "(Required) The IPv4 CIDR address to use to tag the customer side of the connection."
}

variable "amazon_address" {
  type        = string
  description = "(Required) The IPv4 CIDR address to use to tag the Amazon side of the connection."
}

###########################
# Public VIF - Specific
###########################

variable "route_filter_prefixes" {
  type        = list(string)
  description = "(Required if vif_type is 'public') A list of IP prefixes to advertise to the customer for public VIFs."
  default     = []
}

###########################
# Gateway Configuration
###########################

variable "vpn_gateway_id" {
  type        = string
  description = "(Optional) The ID of the virtual private gateway to which the VIF is attached. Required if vif_type is 'private'."
  default     = null
}

variable "direct_connect_gateway_id" {
  type        = string
  description = "(Optional) The ID of the Direct Connect Gateway to which the VIF is attached. Required if vif_type is 'transit'."
  default     = null
}

###########################
# General
###########################

variable "tags" {
  type        = map(any)
  description = "(Optional) A map of tags to assign to the VIF."
  default = {
    created_by = "terraform"
    terraform  = "true"
  }
}
