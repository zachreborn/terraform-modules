mock_provider "aws" {
  mock_resource "aws_route53domains_registered_domain" {
    defaults = {
      creation_date   = "2024-01-01T00:00:00Z"
      expiration_date = "2034-01-01T00:00:00Z"
      updated_date    = "2024-06-01T00:00:00Z"
      whois_server    = "whois.example-registrar.test"
    }
  }
}

run "plan_succeeds_with_single_domain" {
  command = plan

  variables {
    domains = {
      "example.com" = {
        auto_renew    = true
        name_servers  = ["ns1.example.com", "ns2.example.com"]
        transfer_lock = true
      }
    }
  }

  assert {
    condition     = length(aws_route53domains_registered_domain.this) == 1
    error_message = "Expected exactly one domain to be planned."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].auto_renew == true
    error_message = "auto_renew should pass through from the domains map entry."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].transfer_lock == true
    error_message = "transfer_lock should pass through from the domains map entry."
  }

  assert {
    condition     = length(aws_route53domains_registered_domain.this["example.com"].name_server) == 2
    error_message = "Expected two name_server blocks, one per entry in name_servers."
  }

  assert {
    condition     = output.creation_dates["example.com"] == "2024-01-01T00:00:00Z"
    error_message = "creation_dates output should be keyed by domain_name."
  }

  assert {
    condition     = output.expiration_dates["example.com"] == "2034-01-01T00:00:00Z"
    error_message = "expiration_dates output should be keyed by domain_name."
  }

  assert {
    condition     = output.updated_dates["example.com"] == "2024-06-01T00:00:00Z"
    error_message = "updated_dates output should be keyed by domain_name."
  }

  assert {
    condition     = output.whois_servers["example.com"] == "whois.example-registrar.test"
    error_message = "whois_servers output should be keyed by domain_name."
  }
}

run "empty_domains_map_creates_no_resources" {
  command = plan

  variables {
    domains = {}
  }

  assert {
    condition     = length(aws_route53domains_registered_domain.this) == 0
    error_message = "An empty domains map should create no aws_route53domains_registered_domain resources."
  }

  assert {
    condition     = length(output.creation_dates) == 0
    error_message = "creation_dates should be an empty map when no domains are configured."
  }
}

run "multiple_domains_are_all_planned" {
  command = plan

  variables {
    domains = {
      "example.com" = {
        auto_renew    = true
        name_servers  = ["ns1.example.com", "ns2.example.com"]
        transfer_lock = true
      }
      "example.org" = {
        auto_renew    = false
        name_servers  = ["ns1.example.org"]
        transfer_lock = false
      }
    }
  }

  assert {
    condition     = length(aws_route53domains_registered_domain.this) == 2
    error_message = "Expected two domains to be planned."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.org"].auto_renew == false
    error_message = "Each domain entry's auto_renew should be independently honored."
  }

  assert {
    condition     = length(output.creation_dates) == 2
    error_message = "creation_dates should contain an entry for every planned domain."
  }
}

run "domain_with_no_name_servers_creates_no_name_server_blocks" {
  command = plan

  variables {
    domains = {
      "example.com" = {
        auto_renew    = true
        name_servers  = []
        transfer_lock = true
      }
    }
  }

  assert {
    condition     = length(aws_route53domains_registered_domain.this["example.com"].name_server) == 0
    error_message = "An empty name_servers list should result in zero name_server blocks."
  }
}

run "billing_contact_block_is_populated_when_set" {
  command = plan

  variables {
    domains = {
      "example.com" = {
        auto_renew    = true
        name_servers  = ["ns1.example.com"]
        transfer_lock = true
      }
    }
    billing_contact = {
      address_line_1    = "123 Main St"
      address_line_2    = ""
      city              = "Seattle"
      contact_type      = "person"
      country_code      = "us"
      email             = "billing@example.com"
      extra_params      = {}
      fax               = ""
      first_name        = "Jane"
      last_name         = "Doe"
      organization_name = ""
      phone_number      = "+1.5551234567"
      state             = "wa"
      zip_code          = "98101"
    }
  }

  assert {
    condition     = length(aws_route53domains_registered_domain.this["example.com"].billing_contact) == 1
    error_message = "billing_contact block should be present when var.billing_contact is set."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].billing_contact[0].contact_type == "PERSON"
    error_message = "contact_type should be upper-cased by the module."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].billing_contact[0].country_code == "US"
    error_message = "country_code should be upper-cased by the module."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].billing_contact[0].state == "WA"
    error_message = "state should be upper-cased by the module."
  }

  assert {
    condition     = length(aws_route53domains_registered_domain.this["example.com"].admin_contact) == 0
    error_message = "admin_contact should remain omitted when var.admin_contact is null."
  }
}

run "admin_contact_block_is_populated_when_set" {
  command = plan

  variables {
    domains = {
      "example.com" = {
        auto_renew    = true
        name_servers  = ["ns1.example.com"]
        transfer_lock = true
      }
    }
    admin_contact = {
      address_line_1    = "123 Main St"
      address_line_2    = ""
      city              = "Seattle"
      contact_type      = "person"
      country_code      = "us"
      email             = "admin@example.com"
      extra_params      = {}
      fax               = ""
      first_name        = "Jane"
      last_name         = "Doe"
      organization_name = ""
      phone_number      = "+1.5551234567"
      state             = "wa"
      zip_code          = "98101"
    }
  }

  assert {
    condition     = length(aws_route53domains_registered_domain.this["example.com"].admin_contact) == 1
    error_message = "admin_contact block should be present when var.admin_contact is set."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].admin_contact[0].contact_type == "PERSON"
    error_message = "contact_type should be upper-cased by the module."
  }
}

run "registrant_contact_block_is_populated_when_set" {
  command = plan

  variables {
    domains = {
      "example.com" = {
        auto_renew    = true
        name_servers  = ["ns1.example.com"]
        transfer_lock = true
      }
    }
    registrant_contact = {
      address_line_1    = "123 Main St"
      address_line_2    = ""
      city              = "Seattle"
      contact_type      = "company"
      country_code      = "us"
      email             = "registrant@example.com"
      extra_params      = {}
      fax               = ""
      first_name        = "Jane"
      last_name         = "Doe"
      organization_name = "Example Co"
      phone_number      = "+1.5551234567"
      state             = "wa"
      zip_code          = "98101"
    }
  }

  assert {
    condition     = length(aws_route53domains_registered_domain.this["example.com"].registrant_contact) == 1
    error_message = "registrant_contact block should be present when var.registrant_contact is set."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].registrant_contact[0].contact_type == "COMPANY"
    error_message = "contact_type should be upper-cased by the module."
  }
}

run "tech_contact_block_is_populated_when_set" {
  command = plan

  variables {
    domains = {
      "example.com" = {
        auto_renew    = true
        name_servers  = ["ns1.example.com"]
        transfer_lock = true
      }
    }
    tech_contact = {
      address_line_1    = "123 Main St"
      address_line_2    = ""
      city              = "Seattle"
      contact_type      = "person"
      country_code      = "us"
      email             = "tech@example.com"
      extra_params      = {}
      fax               = ""
      first_name        = "Jane"
      last_name         = "Doe"
      organization_name = ""
      phone_number      = "+1.5551234567"
      state             = "wa"
      zip_code          = "98101"
    }
  }

  assert {
    condition     = length(aws_route53domains_registered_domain.this["example.com"].tech_contact) == 1
    error_message = "tech_contact block should be present when var.tech_contact is set."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].tech_contact[0].contact_type == "PERSON"
    error_message = "contact_type should be upper-cased by the module."
  }
}

run "privacy_flags_default_to_true" {
  command = plan

  variables {
    domains = {
      "example.com" = {
        auto_renew    = true
        name_servers  = ["ns1.example.com"]
        transfer_lock = true
      }
    }
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].billing_privacy == true
    error_message = "billing_privacy should default to true."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].admin_privacy == true
    error_message = "admin_privacy should default to true."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].registrant_privacy == true
    error_message = "registrant_privacy should default to true."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].tech_privacy == true
    error_message = "tech_privacy should default to true."
  }
}

run "privacy_flags_can_be_disabled" {
  command = plan

  variables {
    domains = {
      "example.com" = {
        auto_renew    = true
        name_servers  = ["ns1.example.com"]
        transfer_lock = true
      }
    }
    billing_privacy    = false
    admin_privacy      = false
    registrant_privacy = false
    tech_privacy       = false
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].billing_privacy == false
    error_message = "billing_privacy override should be honored."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].admin_privacy == false
    error_message = "admin_privacy override should be honored."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].registrant_privacy == false
    error_message = "registrant_privacy override should be honored."
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].tech_privacy == false
    error_message = "tech_privacy override should be honored."
  }
}

run "tags_default_and_override" {
  command = plan

  variables {
    domains = {
      "example.com" = {
        auto_renew    = true
        name_servers  = ["ns1.example.com"]
        transfer_lock = true
      }
    }
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].tags["terraform"] == "true"
    error_message = "tags should default to { terraform = \"true\" }."
  }
}

run "tags_override_is_honored" {
  command = plan

  variables {
    domains = {
      "example.com" = {
        auto_renew    = true
        name_servers  = ["ns1.example.com"]
        transfer_lock = true
      }
    }
    tags = {
      team = "platform"
    }
  }

  assert {
    condition     = aws_route53domains_registered_domain.this["example.com"].tags["team"] == "platform"
    error_message = "An explicit tags override should be honored."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
