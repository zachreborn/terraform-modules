variable "tags" {
  type        = map(any)
  description = "(Optional) A map of tags to assign to the zone."
  default = {
    terraform = true
  }
}

variable "zones" {
  type = map(object({
    comment           = optional(string) # (Optional) A comment for the hosted zone. Defaults to 'Managed by Terraform'.
    delegation_set_id = optional(string) # (Optional) The ID of the reusable delegation set whose NS records you want to assign to the hosted zone. Conflicts with vpc as delegation sets can only be used for public zones.
    name              = string           # (Required) This is the name of the hosted zone.
  }))
  description = "(Required) A map of hosted zone objects. Key is the name of the hosted zone. Values are the hosted zone configuration settings."
  # Example:
  # zones = {
  #   example.com = {
  #     comment           = "example.com"
  #     delegation_set_id = null
  #     name              = "example.com"
  #   },
  #   example.net = {
  #     comment           = "example.net"
  #     delegation_set_id = null
  #     name              = "example.net"
  #   }
  # }
}
