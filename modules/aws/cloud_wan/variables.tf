###########################
# Resource Variables
###########################

variable "description" {
  description = "(Optional) The description of the global network"
  type        = string
  default     = null
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

variable "name" {
  description = "(Required) The name of the global network"
  type        = string
}

variable "tags" {
  description = "(Optional) Map of tags to assign to the device."
  type        = map(any)
  default = {
    created_by  = "terraform" # Your name goes here
    terraform   = "true"
    environment = "prod"
  }
}
