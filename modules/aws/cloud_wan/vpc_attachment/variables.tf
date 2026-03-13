###########################
# VPC Attachment Variables
###########################
variable "core_network_id" {
  description = "(Required) The ID of the core network for the VPC attachment."
  type        = string
}

variable "vpc_attachments" {
  description = "(Required) Map of VPC attachments to create. The key is the attachment name."
  type = map(object({
    vpc_arn                = string
    subnet_arns            = list(string)
    appliance_mode_support = optional(bool, false)
    ipv6_support           = optional(bool, false)
    routing_policy_label   = optional(string)
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
