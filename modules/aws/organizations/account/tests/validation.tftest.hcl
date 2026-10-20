mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
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
    condition     = length(aws_organizations_account.this) == 1
    error_message = "Expected exactly one account to be planned."
  }
}

run "rejects_entry_with_both_parent_id_and_parent_key" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email      = "jdoe@example.com"
        parent_id  = "r-abcd1234"
        parent_key = "workloads"
      }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_entry_with_neither_parent_id_nor_parent_key" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email = "jdoe@example.com"
      }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_null_entry" {
  command = plan

  variables {
    accounts = {
      company_ventures = null
    }
  }

  expect_failures = [var.accounts]
}

run "accepts_full_allowed_tag_character_set" {
  command = plan

  variables {
    tags = {
      "Café" = "a b"
    }
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
        tags = {
          "purpose"           = "AbZ09 +-=._:/@"
          "a+b-c=d.e_f:g/h@i" = "ok"
        }
      }
    }
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].tags["purpose"] == "AbZ09 +-=._:/@"
    error_message = "A tag value using every allowed character class (letters, digits, space, and + - = . _ : / @) should be accepted and land unchanged on the resource."
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].tags["a+b-c=d.e_f:g/h@i"] == "ok"
    error_message = "A tag key using every allowed punctuation character should be accepted."
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].tags["Café"] == "a b"
    error_message = "A Unicode letter (e.g. accented character) in a module-level tag key should be accepted."
  }
}

run "accepts_empty_tag_value" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
        tags = {
          purpose = ""
        }
      }
    }
  }

  assert {
    condition     = aws_organizations_account.this["company_ventures"].tags["purpose"] == ""
    error_message = "An empty tag value should be accepted and preserved -- AWS permits empty tag values, unlike empty tag keys."
  }
}

run "rejects_entry_tag_value_with_disallowed_character" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
        tags = {
          purpose = "Public-facing personal static websites (S3 + CloudFront)."
        }
      }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_entry_tag_value_with_comma" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
        tags = {
          purpose = "web,api"
        }
      }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_entry_tag_key_with_disallowed_character" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
        tags = {
          "purpose(1)" = "web"
        }
      }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_entry_tag_key_that_is_empty" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
        tags = {
          "" = "web"
        }
      }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_module_tag_value_with_disallowed_character" {
  command = plan

  variables {
    tags = {
      purpose = "Public-facing personal static websites (S3 + CloudFront)."
    }
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
      }
    }
  }

  expect_failures = [var.tags]
}

run "rejects_module_tag_key_with_disallowed_character" {
  command = plan

  variables {
    tags = {
      "purpose(1)" = "web"
    }
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
      }
    }
  }

  expect_failures = [var.tags]
}
