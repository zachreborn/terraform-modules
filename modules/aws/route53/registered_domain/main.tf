terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Data Sources
###########################

########################################
# Route 53 Registered Domains
########################################
resource "aws_route53domains_registered_domain" "this" {
  for_each = var.domains

  admin_privacy      = var.admin_privacy
  auto_renew         = each.value.auto_renew
  domain_name        = each.value
  registrant_privacy = var.registrant_privacy
  tags               = var.tags
  tech_privacy       = var.tech_privacy
  transfer_lock      = each.value.transfer_lock

  admin_contact {
    address_line_1    = var.admin_contact.address_line_1
    address_line_2    = var.admin_contact.address_line_2
    city              = var.admin_contact.city
    contact_type      = var.admin_contact.contact_type
    country_code      = var.admin_contact.country_code
    email             = var.admin_contact.email
    extra_params      = var.admin_contact.extra_params
    fax               = var.admin_contact.fax
    first_name        = var.admin_contact.first_name
    last_name         = var.admin_contact.last_name
    organization_name = var.admin_contact.organization_name
    phone_number      = var.admin_contact.phone_number
    state             = var.admin_contact.state
    zip_code          = var.admin_contact.zip_code
  }

  registrant_contact {
    address_line_1    = var.registrant_contact.address_line_1
    address_line_2    = var.registrant_contact.address_line_2
    city              = var.registrant_contact.city
    contact_type      = var.registrant_contact.contact_type
    country_code      = var.registrant_contact.country_code
    email             = var.registrant_contact.email
    extra_params      = var.registrant_contact.extra_params
    fax               = var.registrant_contact.fax
    first_name        = var.registrant_contact.first_name
    last_name         = var.registrant_contact.last_name
    organization_name = var.registrant_contact.organization_name
    phone_number      = var.registrant_contact.phone_number
    state             = var.registrant_contact.state
    zip_code          = var.registrant_contact.zip_code
  }

  tech_contact {
    address_line_1    = var.tech_contact.address_line_1
    address_line_2    = var.tech_contact.address_line_2
    city              = var.tech_contact.city
    contact_type      = var.tech_contact.contact_type
    country_code      = var.tech_contact.country_code
    email             = var.tech_contact.email
    extra_params      = var.tech_contact.extra_params
    fax               = var.tech_contact.fax
    first_name        = var.tech_contact.first_name
    last_name         = var.tech_contact.last_name
    organization_name = var.tech_contact.organization_name
    phone_number      = var.tech_contact.phone_number
    state             = var.tech_contact.state
    zip_code          = var.tech_contact.zip_code
  }

  dynamic "name_server" {
    for_each = each.value.name_servers

    content {
      name = name_server.value
    }
  }
}
