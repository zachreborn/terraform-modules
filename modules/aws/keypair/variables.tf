variable "key_name_prefix" {
  type        = string
  description = "(Required) Name prefix, used to generate unique keypair name used with AWS services"
}

variable "public_key" {
  type        = string
  description = "(Required) The public key material."
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resource."
  default = {
    terraform = "true"
  }
}
