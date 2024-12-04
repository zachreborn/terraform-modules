##################################
# Transit Gateway Connect Attachment Variables
##################################
variable "protocol" {
  type        = string
  description = "(Optional) The tunnel protocol. Valid values: gre. Default is gre."
  default     = "gre"
  validation {
    condition     = can(regex("^(gre)$", var.protocol))
    error_message = "Invalid protocol. Valid values: gre."
  }
}

variable "transit_gateway_default_route_table_association" {
  type        = bool
  description = "(Optional) Boolean whether the Connect should be associated with the EC2 transit gateway association default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways. Default value: true."
  default     = true
}

variable "transit_gateway_default_route_table_propagation" {
  type        = bool
  description = "(Optional) Boolean whether the Connect should propagate routes with the EC2 transit gateway propagation default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways. Default value: true."
  default     = true
}

variable "transport_attachment_id" {
  type        = string
  description = "(Required) The underlaying transit gateway VPC attachment ID."
}

variable "transit_gateway_id" {
  type        = string
  description = "(Required) Identifier of EC2 transit gateway."
}

##################################
# Transit Gateway Connect Peer Variables
##################################
variable "peers" {
  type = map(object({
    bgp_asn                 = optional(number, 64512) # (Optional) The BGP ASN number assigned customer device. If not provided, it will use the same BGP ASN as is associated with transit gateway.
    inside_cidr_blocks      = list(string)            # (Required) The CIDR block that will be used for addressing within the tunnel. It must contain exactly one IPv4 CIDR block and up to one IPv6 CIDR block. The IPv4 CIDR block must be /29 size and must be within 169.254.0.0/16 range, with exception of: 169.254.0.0/29, 169.254.1.0/29, 169.254.2.0/29, 169.254.3.0/29, 169.254.4.0/29, 169.254.5.0/29, 169.254.169.248/29. The IPv6 CIDR block must be /125 size and must be within fd00::/8. The first IP from each CIDR block is assigned for customer gateway, the second and third is for Transit Gateway (An example: from range 169.254.100.0/29, .1 is assigned to customer gateway and .2 and .3 are assigned to the transit gateway)
    peer_address            = string                  # (Required) The IP addressed assigned to customer device, which will be used as tunnel endpoint. It can be IPv4 or IPv6 address, but must be the same address family as transit_gateway_address
    transit_gateway_address = optional(string)        # (Optional) The IP address assigned to the transit gateway, which will be used as tunnel endpoint. This address must be from associated transit gateway CIDR block. The address must be from the same address family as peer_address. If not set explicitly, it will be selected from associated transit gateway CIDR blocks.
  }))
  description = "(Required) A map of transit gateway connect peers, where the key is the name of the peer and the value is a map of peer configuration options."
  # Example:
  # peers = {
  #   "sdwan_vedge_1" = {
  #     bgp_asn                       = 64513
  #     inside_cidr_blocks            = ["169.254.6.0/29"]
  #     peer_address                  = "10.200.0.157"
  #   }
  #   "sdwan_vedge_1" = {
  #     bgp_asn                       = 64513
  #     inside_cidr_blocks            = ["169.254.6.8/29"]
  #     peer_address                  = "10.200.0.180"
  #   }
  # }
}

##################################
# General Variables
##################################

variable "name" {
  description = "(Required) The name of the transit gateway connect resources."
  type        = string
}

variable "tags" {
  type        = map(any)
  description = "(Optional) Key-value tags for the EC2 transit gateway connect resources. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  default = {
    terraform   = "true"
    environment = "prod"
    project     = "core_infrastructure"
  }
}
