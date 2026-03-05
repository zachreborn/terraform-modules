variable "client_id_list" {
  type        = list(string)
  description = "A list of client IDs (also known as audiences within OIDC). When a mobile or web app registers with an OpenID Connect provider, they establish a value that identifies the application. This is the value that's sent as the client_id parameter on OAuth requests."
}

variable "name" {
  type        = string
  description = "The name of the provider to create, such as Terraform Cloud."
}

variable "tags" {
  type        = map(string)
  description = "Key-value map of resource tags."
  default = {
    terraform = "true"
  }
}

variable "thumbprint_list" {
  type        = list(string)
  description = "A list of server certificate thumbprints for the OpenID Connect (OIDC) identity provider's server certificate(s)."
  default     = null
}

variable "url" {
  type        = string
  description = "The URL of the identity provider. Corresponds to the iss claim."
}
