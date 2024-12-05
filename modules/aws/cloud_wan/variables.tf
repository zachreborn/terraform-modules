###########################
# Resource Variables
###########################

variable "description" {
  description = "(Required) The description of the global network"
  type        = string
}

###########################
# Transit Gateway Variables
###########################

variable "transit_gateway_arns" {
  description = "(Required) List of ARNs of the transit gateways to register with the global network"
  type        = list(string)
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) Map of tags to assign to the device."
  type        = map(any)
  default = {
    created_by  = "terraform" # Your name goes here
    terraform   = "true"
    environment = "prod"
  }
}
