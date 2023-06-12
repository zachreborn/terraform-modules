variable "client_id_list" {
  type        = list(string)
  description = "(Required) A list of client IDs (also known as audiences). When a mobile or web app registers with an OpenID Connect provider, they establish a value that identifies the application. (This is the value that's sent as the client_id parameter on OAuth requests.)"
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Key-value map of resource tags."
  default = {
    terraform = "true"
  }
}

variable "thumbprint_list" {
  type        = list(string)
  description = "(Required) A list of server certificate thumbprints for the OpenID Connect (OIDC) identity provider's server certificate(s)."
}

variable "url" {
  type        = string
  description = "(Required) The URL of the identity provider. Corresponds to the iss claim."
}
