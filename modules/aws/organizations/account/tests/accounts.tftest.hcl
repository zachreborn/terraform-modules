mock_provider "aws" {}

run "literal_parent_id_passes_through" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].parent_id == "r-abcd1234"
    error_message = "Literal parent_id should pass through unchanged."
  }
}

run "parent_key_resolves_through_organizational_unit_ids" {
  command = plan

  variables {
    organizational_unit_ids = {
      workloads = "ou-abcd-11111111"
    }
    accounts = {
      company_ventures = {
        email      = "jdoe@example.com"
        parent_key = "workloads"
      }
    }
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].parent_id == "ou-abcd-11111111"
    error_message = "parent_key should resolve through organizational_unit_ids."
  }
}

run "invalid_parent_key_fails_precondition_not_invalid_index" {
  command = plan

  variables {
    organizational_unit_ids = {
      workloads = "ou-abcd-11111111"
    }
    accounts = {
      company_ventures = {
        email      = "jdoe@example.com"
        parent_key = "does_not_exist"
      }
    }
  }

  expect_failures = [aws_organizations_account.this["company_ventures"]]
}

run "name_defaults_to_map_key" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].name == "company_ventures"
    error_message = "name should default to the entry's map key when unset."
  }
}

run "name_override_is_honored" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        name      = "company.ventures"
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].name == "company.ventures"
    error_message = "Explicit name should override the map key default."
  }
}

run "field_defaults_are_applied" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].iam_user_access_to_billing == null
    error_message = "iam_user_access_to_billing has no module-level default -- it must stay null when unset, so the AWS API can apply its own default without this module ever coercing an unmanaged value."
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].role_name == "OrganizationAccountAccessRole"
    error_message = "role_name should default to OrganizationAccountAccessRole."
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].close_on_deletion == false
    error_message = "close_on_deletion should default to false."
  }
}

run "explicit_null_iam_user_access_to_billing_is_not_coerced" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email                      = "jdoe@example.com"
        parent_id                  = "r-abcd1234"
        iam_user_access_to_billing = null
      }
    }
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].iam_user_access_to_billing == null
    error_message = "An explicit null for iam_user_access_to_billing must pass through unchanged. iam_user_access_to_billing is a ForceNew attribute on aws_organizations_account, so an object-attribute default would silently replace an intentional null with a concrete value and force destroy/recreate of real accounts."
  }
}

run "field_overrides_are_honored" {
  command = plan

  variables {
    accounts = {
      company_security = {
        email                      = "security@example.com"
        parent_id                  = "r-abcd1234"
        iam_user_access_to_billing = "DENY"
        role_name                  = "CustomAccessRole"
        close_on_deletion          = true
      }
    }
  }

  assert {
    condition     = aws_organizations_account.this["company_security"].iam_user_access_to_billing == "DENY"
    error_message = "iam_user_access_to_billing override should be honored."
  }

  assert {
    condition     = aws_organizations_account.this["company_security"].role_name == "CustomAccessRole"
    error_message = "role_name override should be honored."
  }

  assert {
    condition     = aws_organizations_account.this["company_security"].close_on_deletion == true
    error_message = "close_on_deletion override should be honored."
  }
}

run "tags_merge_module_and_entry_tags" {
  command = plan

  variables {
    tags = {
      terraform = "true"
      team      = "platform"
    }
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
        tags = {
          team = "ventures-team"
        }
      }
    }
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].tags["terraform"] == "true"
    error_message = "Module-level tags should be present."
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].tags["team"] == "ventures-team"
    error_message = "Per-account tags should override module-level tags with the same key."
  }
}

run "outputs_expose_keyed_maps" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = output.ids["company_ventures"] != null
    error_message = "ids output should contain the company_ventures key."
  }

  assert {
    condition     = output.arns["company_ventures"] != null
    error_message = "arns output should contain the company_ventures key."
  }

  assert {
    condition     = output.tags_all["company_ventures"] != null
    error_message = "tags_all output should contain the company_ventures key."
  }
}
