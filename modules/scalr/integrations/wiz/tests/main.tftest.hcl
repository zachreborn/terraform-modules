# Native OpenTofu tests for modules/scalr/integrations/wiz (resources, branches, outputs).
# Validation rules are covered in validation.tftest.hcl.
#
# Run offline with:
#   tofu -chdir=modules/scalr/integrations/wiz init -backend=false
#   tofu -chdir=modules/scalr/integrations/wiz test
#
# All credential-shaped values below are obviously fake fixtures.

mock_provider "scalr" {
  mock_resource "scalr_wiz_integration" {
    defaults = {
      id = "in-mock00000000"
    }
  }
}

run "valid_baseline_plans" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name              = "wiz"
        client_id         = "svc-account-client-id"
        default_policies  = ["Default IaC policy", "Secrets policy"]
        default_scan_name = "scalr-scan"
        endpoint_mode     = "govcloud"
        autofail          = true
        environments      = ["env-xxxxxxxxxx", "env-yyyyyyyyyy"]
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  assert {
    condition     = length(scalr_wiz_integration.this) == 1
    error_message = "Expected exactly one Wiz integration to be planned."
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].name == "wiz"
    error_message = "name should be passed through to the resource."
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].client_id == "svc-account-client-id"
    error_message = "client_id should be passed through to the resource."
  }

  assert {
    condition     = nonsensitive(scalr_wiz_integration.this["iac_scanning"].client_secret) == "fake-wiz-client-secret"
    error_message = "client_secret should be looked up from wiz_client_secrets using the entry's key."
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].default_policies == toset(["Default IaC policy", "Secrets policy"])
    error_message = "default_policies should be passed through to the resource."
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].default_scan_name == "scalr-scan"
    error_message = "default_scan_name should be passed through to the resource."
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].endpoint_mode == "govcloud"
    error_message = "endpoint_mode should be passed through to the resource."
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].autofail == true
    error_message = "autofail should be passed through to the resource."
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].environments == toset(["env-xxxxxxxxxx", "env-yyyyyyyyyy"])
    error_message = "environments should be passed through to the resource."
  }

  assert {
    condition     = output.ids["iac_scanning"] == "in-mock00000000"
    error_message = "ids output should map the logical key to the integration ID."
  }
}

###########################################################
# Conditional branch coverage: optional arguments unset
###########################################################

run "optional_arguments_use_documented_defaults_when_unset" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "wiz"
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].endpoint_mode == "commercial"
    error_message = "endpoint_mode should default to 'commercial'."
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].autofail == false
    error_message = "autofail should default to false."
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].default_policies == null
    error_message = "default_policies should remain null when omitted."
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].default_scan_name == null
    error_message = "default_scan_name should remain null when omitted so Scalr names scans {workspace}-{run}."
  }
}

run "explicit_null_endpoint_mode_and_autofail_fall_back_to_defaults" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name          = "wiz"
        client_id     = "svc-account-client-id"
        endpoint_mode = null
        autofail      = null
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].endpoint_mode == "commercial" && scalr_wiz_integration.this["iac_scanning"].autofail == false
    error_message = "Explicit nulls should resolve to the documented defaults ('commercial' and false)."
  }
}

run "endpoint_mode_accepts_every_documented_value" {
  command = plan

  variables {
    wiz_integrations = {
      commercial = {
        name          = "wiz-commercial"
        client_id     = "client-commercial"
        endpoint_mode = "commercial"
      }
      govcloud = {
        name          = "wiz-govcloud"
        client_id     = "client-govcloud"
        endpoint_mode = "govcloud"
      }
      fedramp = {
        name          = "wiz-fedramp"
        client_id     = "client-fedramp"
        endpoint_mode = "fedramp"
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      commercial = "fake-secret-commercial"
      govcloud   = "fake-secret-govcloud"
      fedramp    = "fake-secret-fedramp"
    }
  }

  assert {
    condition = (
      scalr_wiz_integration.this["commercial"].endpoint_mode == "commercial" &&
      scalr_wiz_integration.this["govcloud"].endpoint_mode == "govcloud" &&
      scalr_wiz_integration.this["fedramp"].endpoint_mode == "fedramp"
    )
    error_message = "Each documented endpoint_mode value should reach the matching resource."
  }
}

###########################################################
# Conditional branch coverage: environments
###########################################################

run "environments_accepts_wildcard_alone" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name         = "wiz"
        client_id    = "svc-account-client-id"
        environments = ["*"]
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  assert {
    condition     = scalr_wiz_integration.this["iac_scanning"].environments == toset(["*"])
    error_message = "A lone '*' (all environments) should be passed through unchanged."
  }
}

run "environments_accepts_empty_set" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name         = "wiz"
        client_id    = "svc-account-client-id"
        environments = []
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
    }
  }

  assert {
    condition     = length(scalr_wiz_integration.this["iac_scanning"].environments) == 0
    error_message = "An explicit empty environments set (no environment links) should be passed through."
  }
}

###########################################################
# for_each scaling: each entry receives its own client secret
###########################################################

run "multiple_integrations_each_get_their_own_client_secret" {
  command = plan

  variables {
    wiz_integrations = {
      prod = {
        name         = "wiz-prod"
        client_id    = "client-prod"
        environments = ["*"]
      }
      dev = {
        name         = "wiz-dev"
        client_id    = "client-dev"
        environments = ["env-xxxxxxxxxx"]
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      prod = "fake-secret-prod"
      dev  = "fake-secret-dev"
    }
  }

  assert {
    condition     = length(scalr_wiz_integration.this) == 2
    error_message = "Expected one resource instance per wiz_integrations entry."
  }

  assert {
    condition = (
      nonsensitive(scalr_wiz_integration.this["prod"].client_secret) == "fake-secret-prod" &&
      nonsensitive(scalr_wiz_integration.this["dev"].client_secret) == "fake-secret-dev"
    )
    error_message = "Each integration must receive the client secret stored under its own key (no cross-wiring)."
  }

  assert {
    condition     = toset(keys(output.ids)) == toset(["prod", "dev"])
    error_message = "ids output should contain one entry per logical key."
  }
}

run "extra_client_secrets_without_an_integration_are_ignored" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "wiz"
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning = "fake-wiz-client-secret"
      unused       = "fake-unused-secret"
    }
  }

  assert {
    condition     = length(scalr_wiz_integration.this) == 1
    error_message = "A surplus wiz_client_secrets entry must not create an integration."
  }
}

run "invalid_unused_client_secrets_do_not_block_valid_integrations" {
  command = plan

  variables {
    wiz_integrations = {
      iac_scanning = {
        name      = "wiz"
        client_id = "svc-account-client-id"
      }
    }
    wiz_client_secrets = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      iac_scanning     = "fake-wiz-client-secret"
      unused_null      = null
      unused_empty     = ""
      unused_blank     = "   "
      unused_oversized = join("", [for i in range(513) : "a"])
    }
  }

  assert {
    condition     = length(scalr_wiz_integration.this) == 1
    error_message = "Null, empty, blank, or oversized values under keys with no matching integration must not fail validation."
  }

  assert {
    condition     = nonsensitive(scalr_wiz_integration.this["iac_scanning"].client_secret) == "fake-wiz-client-secret"
    error_message = "The configured integration must still receive its own client secret."
  }
}

run "invalid_unused_client_secrets_are_ignored_when_no_integrations_are_configured" {
  command = plan

  variables {
    wiz_integrations = {}
    wiz_client_secrets = {
      unused_null      = null
      unused_empty     = ""
      unused_oversized = join("", [for i in range(513) : "a"])
    }
  }

  assert {
    condition     = length(scalr_wiz_integration.this) == 0
    error_message = "With no integrations configured, every wiz_client_secrets entry is unused and must be ignored, whatever its value."
  }
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_integrations" {
  command = plan

  assert {
    condition     = length(scalr_wiz_integration.this) == 0
    error_message = "An empty wiz_integrations map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no integrations are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
