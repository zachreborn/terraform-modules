###########################
# Direct Connect Gateway
###########################

variable "name" {
  description = "(Required) The name of the Direct Connect gateway."
  type        = string
}

variable "amazon_side_asn" {
  description = "(Required) The ASN for the Amazon side of the BGP session. Must be in the private range 64512-65534 or 4200000000-4294967294."
  type        = string
  validation {
    condition = (
      (tonumber(var.amazon_side_asn) >= 64512 && tonumber(var.amazon_side_asn) <= 65534) ||
      (tonumber(var.amazon_side_asn) >= 4200000000 && tonumber(var.amazon_side_asn) <= 4294967294)
    )
    error_message = "amazon_side_asn must be in the private range 64512-65534 or 4200000000-4294967294."
  }
}

###########################
# Tags
###########################

variable "tags" {
  description = "(Optional) Map of tags to assign to the gateway. A Name tag is automatically added from var.name."
  type        = map(string)
  default     = {}
}
