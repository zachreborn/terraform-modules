###########################
# Connect Peer Variables
###########################
variable "connect_attachment_id" {
  description = "(Required) The ID of the connect attachment."
  type        = string
}

variable "peers" {
  description = "(Required) Map of BGP peers to create. The key is the peer name."
  type = map(object({
    peer_address         = string
    bgp_asn              = number
    core_network_address = optional(string)
    inside_cidr_blocks   = optional(list(string))
    subnet_arn           = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.peers :
      (v.bgp_asn >= 1 && v.bgp_asn <= 65534) || (v.bgp_asn >= 4200000000 && v.bgp_asn <= 4294967294)
    ])
    error_message = "BGP ASN must be in the range 1-65534 or 4200000000-4294967294."
  }
}

###########################
# General Variables
###########################
variable "tags" {
  description = "(Optional) Map of tags to assign to the resource."
  type        = map(any)
  default = {
    created_by  = "terraform"
    terraform   = "true"
    environment = "prod"
  }
}
