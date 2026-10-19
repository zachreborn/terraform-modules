# Native OpenTofu validation tests for modules/scalr/integrations/wiz.
# One `expect_failures` run per distinct way each validation block can fail.
#
# All credential-shaped values below are obviously fake fixtures.

mock_provider "scalr" {
  mock_resource "scalr_wiz_integration" {
    defaults = {
      id = "in-mock00000000"
    }
  }
}

###########################################################
# wiz_integrations: name
###########################################################

run "rejects_blank_name" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "   "
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  expect_failures = [var.wiz_integrations]
}

run "rejects_name_longer_than_128_characters" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = join("", [for i in range(129) : "a"])
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  expect_failures = [var.wiz_integrations]
}

run "accepts_name_of_exactly_128_characters" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = join("", [for i in range(128) : "a"])
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  assert {
    condition     = length(scalr_wiz_integration.this["iac_scanning"].name) == 128
    error_message = "A 128-character name is the documented upper bound and must be accepted."
  }
}

###########################################################
# wiz_integrations: client_id
###########################################################

run "rejects_blank_client_id" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "wiz"
        client_id = ""
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  expect_failures = [var.wiz_integrations]
}

run "rejects_client_id_longer_than_255_characters" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "wiz"
        client_id = join("", [for i in range(256) : "a"])
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  expect_failures = [var.wiz_integrations]
}

###########################################################
# wiz_integrations: default_scan_name
###########################################################

run "rejects_blank_default_scan_name" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name              = "wiz"
        client_id         = "svc-account-client-id"
        default_scan_name = "  "
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  expect_failures = [var.wiz_integrations]
}

run "rejects_default_scan_name_longer_than_255_characters" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name              = "wiz"
        client_id         = "svc-account-client-id"
        default_scan_name = join("", [for i in range(256) : "a"])
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  expect_failures = [var.wiz_integrations]
}

###########################################################
# wiz_integrations: default_policies
###########################################################

run "rejects_blank_default_policy" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name             = "wiz"
        client_id        = "svc-account-client-id"
        default_policies = ["Default IaC policy", " "]
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  expect_failures = [var.wiz_integrations]
}

###########################################################
# wiz_integrations: endpoint_mode
###########################################################

run "rejects_invalid_endpoint_mode" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name          = "wiz"
        client_id     = "svc-account-client-id"
        endpoint_mode = "not_a_real_mode"
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  expect_failures = [var.wiz_integrations]
}

run "rejects_endpoint_mode_with_wrong_case" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name          = "wiz"
        client_id     = "svc-account-client-id"
        endpoint_mode = "GovCloud"
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  expect_failures = [var.wiz_integrations]
}

###########################################################
# wiz_integrations: environments
###########################################################

run "rejects_blank_environment" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name         = "wiz"
        client_id    = "svc-account-client-id"
        environments = ["env-xxxxxxxxxx", ""]
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  expect_failures = [var.wiz_integrations]
}

run "rejects_wildcard_mixed_with_explicit_environments" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name         = "wiz"
        client_id    = "svc-account-client-id"
        environments = ["*", "env-xxxxxxxxxx"]
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  expect_failures = [var.wiz_integrations]
}

###########################################################
# wiz_client_secrets: coverage and content
###########################################################

run "rejects_integration_without_matching_client_secret" {
  command = plan

  variables {
    wiz_integrations = {
      prod = {
        name      = "wiz-prod"
        client_id = "client-prod"
      }
      dev = {
        name      = "wiz-dev"
        client_id = "client-dev"
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      prod = "fake-secret-prod"
    }
  }

  expect_failures = [var.wiz_client_secrets]
}

run "rejects_integration_when_client_secret_map_is_empty" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "wiz"
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {}
  }

  expect_failures = [var.wiz_client_secrets]
}

run "rejects_empty_client_secret" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "wiz"
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {
      iac_scanning = ""
    }
  }

  expect_failures = [var.wiz_client_secrets]
}

run "rejects_whitespace_only_client_secret" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "wiz"
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {
      iac_scanning = "   "
    }
  }

  expect_failures = [var.wiz_client_secrets]
}

run "rejects_null_client_secret" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "wiz"
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {
      iac_scanning = null
    }
  }

  expect_failures = [var.wiz_client_secrets]
}

run "rejects_client_secret_longer_than_512_characters" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "wiz"
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {
      iac_scanning = join("", [for i in range(513) : "a"])
    }
  }

  expect_failures = [var.wiz_client_secrets]
}

run "accepts_client_secret_of_exactly_512_characters" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "wiz"
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {
      iac_scanning = join("", [for i in range(512) : "a"])
    }
  }

  assert {
    condition     = length(nonsensitive(scalr_wiz_integration.this["iac_scanning"].client_secret)) == 512
    error_message = "A 512-character client secret is the documented upper bound and must be accepted."
  }
}

# Do NOT delete, skip, or loosen an `expect_failures` case just to make `tofu test` pass. A
# validation test that unexpectedly fails means either the `validation {}` block in variables.tf
# has a bug or the test's inputs are wrong -- find and fix the root cause, then re-run
# `tofu test` until it passes for the right reason.
