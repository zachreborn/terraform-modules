variable "admin_contact" {
  description = "The admin contact information for the domain."
  type = object({
    address_line_1    = string
    address_line_2    = string
    city              = string
    contact_type      = string
    country_code      = string
    email             = string
    extra_params      = map(string)
    fax               = string
    first_name        = string
    last_name         = string
    organization_name = string
    phone_number      = string
    state             = string
    zip_code          = string
  })
}

variable "admin_privacy" {
  description = "Whether to enable admin privacy protection. Default is true."
  type        = bool
  default     = true
}

variable "domains" {
  description = "A map of domains to register with Route53."
  type = map(object({
    auto_renew    = bool
    name_servers  = list(string)
    transfer_lock = bool
  }))
  # Example:
  # domains = {
  #   example.com = {
  #     auto_renew = true
  #     name_servers = [ "ns-123.awsdns-12.com", "ns-456.awsdns-34.net" ]
  #     transfer_lock = true
  #   },
  #   example.org = {
  #     auto_renew = true
  #     name_servers = [ "ns-123.awsdns-12.com", "ns-456.awsdns-34.net" ]
  #     transfer_lock = true
  #   }
  # }
}

variable "registrant_contact" {
  description = "The registrant contact information for the domain."
  type = object({
    address_line_1    = string
    address_line_2    = string
    city              = string
    contact_type      = string
    country_code      = string
    email             = string
    extra_params      = map(string)
    fax               = string
    first_name        = string
    last_name         = string
    organization_name = string
    phone_number      = string
    state             = string
    zip_code          = string
  })
}

variable "registrant_privacy" {
  description = "Whether to enable registrant privacy protection. Default is true."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = { terraform = "true" }
}

variable "tech_contact" {
  description = "The tech contact information for the domain."
  type = object({
    address_line_1    = string
    address_line_2    = string
    city              = string
    contact_type      = string
    country_code      = string
    email             = string
    extra_params      = map(string)
    fax               = string
    first_name        = string
    last_name         = string
    organization_name = string
    phone_number      = string
    state             = string
    zip_code          = string
  })
}

variable "tech_privacy" {
  description = "Whether to enable tech privacy protection. Default is true."
  type        = bool
  default     = true
}
