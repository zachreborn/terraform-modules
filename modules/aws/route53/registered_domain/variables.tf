########################################
# Route 53 Registered Domains Variables
########################################

variable "admin_contact" {
  description = "The admin contact information for the domain."
  type = map(object({
    address_line_1    = string
    address_line_2    = string
    city              = string
    contact_type      = string
    country_code      = string
    email             = string
    extra_params      = map(any)
    fax               = string
    first_name        = string
    last_name         = string
    organization_name = string
    phone_number      = string
    state             = string
    zip_code          = string
  }))
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
  #     admin_contact      = var.admin_contact
  #     auto_renew         = true
  #     name_servers       = [ "ns-123.awsdns-12.com", "ns-456.awsdns-34.net" ]
  #     registrant_contact = var.registrant_contact
  #     tech_contact       = var.tech_contact
  #     transfer_lock      = true
  #   },
  #   example.org = {
  #     admin_contact      = var.admin_contact
  #     auto_renew         = true
  #     name_servers       = [ "ns-123.awsdns-12.com", "ns-456.awsdns-34.net" ]
  #     registrant_contact = var.registrant_contact
  #     tech_contact       = var.tech_contact
  #     transfer_lock      = true
  #   }
  # }
}

variable "registrant_contact" {
  description = "The registrant contact information for the domain."
  type = map(object({
    address_line_1    = string
    address_line_2    = string
    city              = string
    contact_type      = string
    country_code      = string
    email             = string
    extra_params      = map(any)
    fax               = string
    first_name        = string
    last_name         = string
    organization_name = string
    phone_number      = string
    state             = string
    zip_code          = string
  }))
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
  type = map(object({
    address_line_1    = string
    address_line_2    = string
    city              = string
    contact_type      = string
    country_code      = string
    email             = string
    extra_params      = map(any)
    fax               = string
    first_name        = string
    last_name         = string
    organization_name = string
    phone_number      = string
    state             = string
    zip_code          = string
  }))
}

variable "tech_privacy" {
  description = "Whether to enable tech privacy protection. Default is true."
  type        = bool
  default     = true
}
