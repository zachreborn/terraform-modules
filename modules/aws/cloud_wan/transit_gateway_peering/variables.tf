###########################
# Transit Gateway Peering Variables
###########################
variable "core_network_id" {
  description = "(Required) The ID of the core network."
  type        = string
}

variable "peerings" {
  description = "(Required) Map of transit gateway peerings to create. The key is the peering name."
  type = map(object({
    transit_gateway_arn = string
  }))
  default = {}
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
