# Native OpenTofu tests for modules/scalr/integrations/datadog (resources, branches, outputs).
# Validation rules are covered in validation.tftest.hcl.
#
# Run offline with:
#   tofu -chdir=modules/scalr/integrations/datadog init -backend=false
#   tofu -chdir=modules/scalr/integrations/datadog test
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

run "valid_baseline_plans" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name           = "datadog"
        deployment_url = "https://us5.datadoghq.com"
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
    }
  }

  assert {
    condition     = length(scalr_datadog_integration.this) == 1
    error_message = "Expected exactly one Datadog integration to be planned."
  }

  assert {
    condition     = scalr_datadog_integration.this["primary"].name == "datadog"
    error_message = "name should be passed through to the resource."
  }

  assert {
    condition     = scalr_datadog_integration.this["primary"].deployment_url == "https://us5.datadoghq.com"
    error_message = "deployment_url should be passed through to the resource."
  }

  assert {
    condition     = nonsensitive(scalr_datadog_integration.this["primary"].api_key) == "fake-datadog-api-key"
    error_message = "api_key should be looked up from datadog_api_keys using the entry's key."
  }

  assert {
    condition     = output.ids["primary"] == "in-mock00000000"
    error_message = "ids output should map the logical key to the integration ID."
  }

  assert {
    condition     = output.statuses["primary"] == "active"
    error_message = "statuses output should map the logical key to the integration status."
  }

  assert {
    condition     = output.err_messages["primary"] == ""
    error_message = "err_messages output should map the logical key to the integration error message."
  }

  assert {
    condition     = output.account_ids["primary"] == "acc-mock00000000"
    error_message = "account_ids output should map the logical key to the owning account ID."
  }
}

###########################################################
# Conditional branch coverage: deployment_url unset / set
###########################################################

run "deployment_url_defaults_to_null_when_unset" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name = "datadog"
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
    }
  }

  assert {
    condition     = scalr_datadog_integration.this["primary"].deployment_url == null
    error_message = "deployment_url should remain null when omitted so Scalr applies its own default site."
  }
}

run "deployment_url_accepts_host_with_port_and_path" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name           = "datadog"
        deployment_url = "https://api.datadoghq.eu:443/"
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
    }
  }

  assert {
    condition     = scalr_datadog_integration.this["primary"].deployment_url == "https://api.datadoghq.eu:443/"
    error_message = "A valid https URL with a port and trailing slash should be accepted unchanged."
  }
}

###########################################################
# for_each scaling: each entry receives its own API key
###########################################################

run "multiple_integrations_each_get_their_own_api_key" {
  command = plan

  variables {
    datadog_integrations = {
      us = {
        name           = "datadog-us"
        deployment_url = "https://us5.datadoghq.com"
      }
      eu = {
        name           = "datadog-eu"
        deployment_url = "https://api.datadoghq.eu"
      }
      default_site = {
        name = "datadog-default"
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      us           = "fake-key-us"
      eu           = "fake-key-eu"
      default_site = "fake-key-default"
    }
  }

  assert {
    condition     = length(scalr_datadog_integration.this) == 3
    error_message = "Expected one resource instance per datadog_integrations entry."
  }

  assert {
    condition = (
      nonsensitive(scalr_datadog_integration.this["us"].api_key) == "fake-key-us" &&
      nonsensitive(scalr_datadog_integration.this["eu"].api_key) == "fake-key-eu" &&
      nonsensitive(scalr_datadog_integration.this["default_site"].api_key) == "fake-key-default"
    )
    error_message = "Each integration must receive the API key stored under its own key (no cross-wiring)."
  }

  assert {
    condition     = toset(keys(output.ids)) == toset(["us", "eu", "default_site"])
    error_message = "ids output should contain one entry per logical key."
  }

  assert {
    condition     = toset(keys(output.statuses)) == toset(["us", "eu", "default_site"]) && toset(keys(output.err_messages)) == toset(["us", "eu", "default_site"]) && toset(keys(output.account_ids)) == toset(["us", "eu", "default_site"])
    error_message = "statuses, err_messages, and account_ids outputs should contain one entry per logical key."
  }
}

run "extra_api_keys_without_an_integration_are_ignored" {
  command = plan

  variables {
    datadog_integrations = {
      primary = {
        name = "datadog"
      }
    }
    datadog_api_keys = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      primary = "fake-datadog-api-key"
      unused  = "fake-unused-key"
    }
  }

  assert {
    condition     = length(scalr_datadog_integration.this) == 1
    error_message = "A surplus datadog_api_keys entry must not create an integration."
  }
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_integrations" {
  command = plan

  assert {
    condition     = length(scalr_datadog_integration.this) == 0
    error_message = "An empty datadog_integrations map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0 && length(output.statuses) == 0 && length(output.err_messages) == 0 && length(output.account_ids) == 0
    error_message = "All outputs should be empty when no integrations are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
