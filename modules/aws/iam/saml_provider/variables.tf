variable "name" {
  type        = string
  description = "(Required) The name of the provider to create."
}

variable "saml_metadata_document" {
  type        = string
  description = "(Required) An XML document generated by an identity provider that supports SAML 2.0."
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to the IAM SAML provider."
  default = {
    terraform = "true"
  }
}