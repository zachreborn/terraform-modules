variable "name" {
  type        = string
  description = "(Required) The name of the transit gateway"
}

variable "peers" {
  type = map(object({
    bgp_asn                 = optional(number, 64512) # (Optional) The BGP ASN number assigned customer device. If not provided, it will use the same BGP ASN as is associated with Transit Gateway.
    inside_cidr_blocks      = list(string)            # (Required) The CIDR block that will be used for addressing within the tunnel. It must contain exactly one IPv4 CIDR block and up to one IPv6 CIDR block. The IPv4 CIDR block must be /29 size and must be within 169.254.0.0/16 range, with exception of: 169.254.0.0/29, 169.254.1.0/29, 169.254.2.0/29, 169.254.3.0/29, 169.254.4.0/29, 169.254.5.0/29, 169.254.169.248/29. The IPv6 CIDR block must be /125 size and must be within fd00::/8. The first IP from each CIDR block is assigned for customer gateway, the second and third is for Transit Gateway (An example: from range 169.254.100.0/29, .1 is assigned to customer gateway and .2 and .3 are assigned to Transit Gateway)
    peer_address            = string                  # (Required) The IP addressed assigned to customer device, which will be used as tunnel endpoint. It can be IPv4 or IPv6 address, but must be the same address family as transit_gateway_address
    transit_gateway_address = optional(string)        # (Optional) The IP address assigned to Transit Gateway, which will be used as tunnel endpoint. This address must be from associated Transit Gateway CIDR block. The address must be from the same address family as peer_address. If not set explicitly, it will be selected from associated Transit Gateway CIDR blocks.
  }))
  description = "(Required) A map of Transit Gateway Connect Peers, where the key is the name of the peer and the value is a map of peer configuration options."
  # Example:
  # var.peers = {
  #   "sdwan_vedge_1" = {
  #     bgp_asn                       = 64513
  #     inside_cidr_blocks            = ["169.254.6.0/29"]
  #     peer_address                  = "10.200.0.157"
  #   }
  #   "sdwan_vedge_1" = {
  #     bgp_asn                       = 64513
  #     inside_cidr_blocks            = ["169.254.7.0/29"]
  #     peer_address                  = "10.200.0.180"
  #   }
  # }
}

variable "tags" {
  type        = map(any)
  description = "(Optional) Key-value tags for the EC2 Transit Gateway Connect. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  default = {
    terraform   = "true"
    environment = "prod"
    project     = "core_infrastructure"
  }
}

# variable "transit_gateway_address" {
#   type        = string
#   description = "(Optional) The IP address assigned to Transit Gateway, which will be used as tunnel endpoint. This address must be from associated Transit Gateway CIDR block. The address must be from the same address family as peer_address. If not set explicitly, it will be selected from associated Transit Gateway CIDR blocks"
#   default     = null
# }

variable "transit_gateway_attachment_id" {
  type        = string
  description = "(Required) The Transit Gateway Connect"
}
