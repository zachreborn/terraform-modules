# Native OpenTofu validation tests for modules/scalr/integrations/datadog.
# One `expect_failures` run per distinct way each validation block can fail.
#
# All credential-shaped values below are obviously fake fixtures.

mock_provider "scalr" {
  mock_resource "scalr_datadog_integration" {
    defaults = {
      id          = "in-mock00000000"
      status      = "active"
      err_message = ""
      account_id  = "acc-mock00000000"
    }
  }
}

###########################################################
# datadog_integrations: name
###########################################################

run "rejects_blank_name" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name = "   "
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
    }
  }

  expect_failures = [var.datadog_integrations]
}

run "rejects_name_longer_than_128_characters" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name = join("", [for i in range(129) : "a"])
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
    }
  }

  expect_failures = [var.datadog_integrations]
}

run "accepts_name_of_exactly_128_characters" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name = join("", [for i in range(128) : "a"])
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
    }
  }

  assert {
    condition     = length(scalr_datadog_integration.this["primary"].name) == 128
    error_message = "A 128-character name is the documented upper bound and must be accepted."
  }
}

###########################################################
# datadog_integrations: deployment_url
###########################################################

run "rejects_http_deployment_url" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name           = "datadog"
        deployment_url = "http://us5.datadoghq.com"
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
    }
  }

  expect_failures = [var.datadog_integrations]
}

run "rejects_deployment_url_without_scheme" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name           = "datadog"
        deployment_url = "us5.datadoghq.com"
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
    }
  }

  expect_failures = [var.datadog_integrations]
}

run "rejects_empty_deployment_url" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name           = "datadog"
        deployment_url = ""
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
    }
  }

  expect_failures = [var.datadog_integrations]
}

run "rejects_deployment_url_with_embedded_credentials" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name           = "datadog"
        deployment_url = "https://user:pass@us5.datadoghq.com"
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
    }
  }

  expect_failures = [var.datadog_integrations]
}

###########################################################
# datadog_api_keys: coverage and content
###########################################################

run "rejects_integration_without_matching_api_key" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name = "datadog"
      }
      secondary = {
        name = "datadog-2"
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
    }
  }

  expect_failures = [var.datadog_api_keys]
}

run "rejects_integration_when_api_key_map_is_empty" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name = "datadog"
      }
    }
    datadog_api_keys = {}
  }

  expect_failures = [var.datadog_api_keys]
}

run "rejects_empty_api_key" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name = "datadog"
      }
    }
    datadog_api_keys = {
      primary = ""
    }
  }

  expect_failures = [var.datadog_api_keys]
}

run "rejects_whitespace_only_api_key" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name = "datadog"
      }
    }
    datadog_api_keys = {
      primary = "   "
    }
  }

  expect_failures = [var.datadog_api_keys]
}

run "rejects_null_api_key" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name = "datadog"
      }
    }
    datadog_api_keys = {
      primary = null
    }
  }

  expect_failures = [var.datadog_api_keys]
}

# Do NOT delete, skip, or loosen an `expect_failures` case just to make `tofu test` pass. A
# validation test that unexpectedly fails means either the `validation {}` block in variables.tf
# has a bug or the test's inputs are wrong -- find and fix the root cause, then re-run
# `tofu test` until it passes for the right reason.
