###########################
# Connect Attachment Variables
###########################
variable "core_network_id" {
  description = "(Required) The ID of the core network for the connect attachment."
  type        = string
}

variable "connect_attachments" {
  description = "(Required) Map of connect attachments to create. The key is the attachment name."
  type = map(object({
    transport_attachment_id = string
    edge_location           = string
    protocol                = string
    proposed_segment_change = optional(object({
      attachment_policy_rule_number = optional(number)
      segment_name                  = optional(string)
      tags                          = optional(map(string))
    }))
    proposed_network_function_group_change = optional(object({
      attachment_policy_rule_number = optional(number)
      network_function_group_name   = optional(string)
      tags                          = optional(map(string))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.connect_attachments :
      contains(["NO_ENCAP", "GRE"], v.protocol)
    ])
    error_message = "Protocol must be either 'NO_ENCAP' (tunnel-less) or 'GRE'."
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
