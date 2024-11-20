variable "carrier_gateway_id" {
  type        = string
  description = "(Optional) Identifier of a carrier gateway. This attribute can only be used when the VPC contains a subnet which is associated with a Wavelength Zone."
  default     = null
}

variable "destination_cidr_block" {
  type        = string
  description = " (Optional) The destination CIDR block."
}

variable "destination_ipv6_cidr_block" {
  type        = string
  description = "(Optional) The destination IPv6 CIDR block."
  default     = null
}

variable "egress_only_gateway_id" {
  type        = string
  description = "(Optional) An ID of a VPC Egress Only Internet Gateway."
  default     = null
}

variable "gateway_id" {
  type        = string
  description = "(Optional) An ID of a VPC internet gateway or a virtual private gateway."
  default     = null
}

variable "local_gateway_id" {
  type        = string
  description = "(Optional) Identifier of a Outpost local gateway."
  default     = null
}

variable "nat_gateway_id" {
  type        = string
  description = "(Optional) An ID of a VPC NAT gateway."
  default     = null
}

variable "network_interface_id" {
  type        = string
  description = "(Optional) An ID of a network interface."
  default     = null
}

variable "transit_gateway_id" {
  type        = string
  description = "(Optional) Identifier of an EC2 Transit Gateway."
  default     = null
}

variable "route_table_ids" {
  type        = list(any)
  description = "(Required) The IDs of the routing tables to apply the route to."
}

variable "vpc_endpoint_id" {
  type        = string
  description = "(Optional) Identifier of a VPC Endpoint."
  default     = null
}

variable "vpc_peering_connection_id" {
  type        = string
  description = "(Optional) An ID of a VPC peering connection."
  default     = null
}
