# Native OpenTofu tests for modules/scalr/module/test_provider_configuration
#
# Run offline with:
#   tofu -chdir=modules/scalr/module/test_provider_configuration init -backend=false
#   tofu -chdir=modules/scalr/module/test_provider_configuration test

mock_provider "scalr" {
  mock_resource "scalr_module_test_provider_configuration" {
    defaults = {
      id = "tpcfgl-xxxxxxxxxx"
    }
  }
}

###########################################################
# Valid baseline
###########################################################

run "valid_baseline_plans" {
  command = plan

  variables {
    module_test_provider_configurations = {
      vpc_aws = {
        test_configuration_id     = "tc-xxxxxxxxxx"
        provider_configuration_id = "pcfg-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_module_test_provider_configuration.this) == 1
    error_message = "Expected exactly one module test provider configuration link to be planned."
  }

  assert {
    condition     = scalr_module_test_provider_configuration.this["vpc_aws"].test_configuration_id == "tc-xxxxxxxxxx"
    error_message = "test_configuration_id should be passed through unchanged."
  }

  assert {
    condition     = scalr_module_test_provider_configuration.this["vpc_aws"].provider_configuration_id == "pcfg-xxxxxxxxxx"
    error_message = "provider_configuration_id should be passed through unchanged."
  }

  assert {
    condition     = output.ids["vpc_aws"] == "tpcfgl-xxxxxxxxxx"
    error_message = "ids output should expose the (mocked) tpcfgl- ID under the logical key."
  }

  assert {
    condition     = output.links["vpc_aws"].test_configuration_id == "tc-xxxxxxxxxx"
    error_message = "links output should expose the resolved test_configuration_id."
  }

  assert {
    condition     = output.links["vpc_aws"].provider_configuration_id == "pcfg-xxxxxxxxxx"
    error_message = "links output should expose the resolved provider_configuration_id."
  }

  assert {
    condition     = output.links["vpc_aws"].id == output.ids["vpc_aws"]
    error_message = "links output id should match the ids output."
  }
}

###########################################################
# Multiple links: one test configuration with several provider types, and several test configurations
###########################################################

run "multiple_links_scale_with_one_call" {
  command = plan

  variables {
    module_test_provider_configurations = {
      vpc_aws = {
        test_configuration_id     = "tc-aaaaaaaaaa"
        provider_configuration_id = "pcfg-aws0000000"
      }
      vpc_azurerm = {
        test_configuration_id     = "tc-aaaaaaaaaa"
        provider_configuration_id = "pcfg-azurerm000"
      }
      rds_aws = {
        test_configuration_id     = "tc-bbbbbbbbbb"
        provider_configuration_id = "pcfg-aws0000000"
      }
    }
  }

  assert {
    condition     = length(scalr_module_test_provider_configuration.this) == 3
    error_message = "Expected three links for three entries."
  }

  assert {
    condition     = length(output.ids) == 3
    error_message = "ids output should contain all three entries."
  }

  assert {
    condition     = output.links["vpc_azurerm"].test_configuration_id == "tc-aaaaaaaaaa" && output.links["vpc_azurerm"].provider_configuration_id == "pcfg-azurerm000"
    error_message = "Each entry should keep its own test_configuration_id / provider_configuration_id pair."
  }

  assert {
    condition     = output.links["rds_aws"].test_configuration_id == "tc-bbbbbbbbbb"
    error_message = "The same provider configuration may be linked to more than one test configuration."
  }
}

###########################################################
# Validation: expect_failures
###########################################################

run "rejects_test_configuration_id_without_tc_prefix" {
  command = plan

  variables {
    module_test_provider_configurations = {
      vpc_aws = {
        test_configuration_id     = "mod-xxxxxxxxxx"
        provider_configuration_id = "pcfg-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.module_test_provider_configurations]
}

run "rejects_empty_test_configuration_id" {
  command = plan

  variables {
    module_test_provider_configurations = {
      vpc_aws = {
        test_configuration_id     = ""
        provider_configuration_id = "pcfg-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.module_test_provider_configurations]
}

# Explicit nulls must fail validation cleanly instead of raising an evaluation error from startswith(null, ...).
run "rejects_null_test_configuration_id" {
  command = plan

  variables {
    module_test_provider_configurations = {
      vpc_aws = {
        test_configuration_id     = null
        provider_configuration_id = "pcfg-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.module_test_provider_configurations]
}

run "rejects_null_provider_configuration_id" {
  command = plan

  variables {
    module_test_provider_configurations = {
      vpc_aws = {
        test_configuration_id     = "tc-xxxxxxxxxx"
        provider_configuration_id = null
      }
    }
  }

  expect_failures = [var.module_test_provider_configurations]
}

run "rejects_provider_configuration_id_without_pcfg_prefix" {
  command = plan

  variables {
    module_test_provider_configurations = {
      vpc_aws = {
        test_configuration_id     = "tc-xxxxxxxxxx"
        provider_configuration_id = "env-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.module_test_provider_configurations]
}

run "rejects_empty_provider_configuration_id" {
  command = plan

  variables {
    module_test_provider_configurations = {
      vpc_aws = {
        test_configuration_id     = "tc-xxxxxxxxxx"
        provider_configuration_id = ""
      }
    }
  }

  expect_failures = [var.module_test_provider_configurations]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_links" {
  command = plan

  assert {
    condition     = length(scalr_module_test_provider_configuration.this) == 0
    error_message = "An empty module_test_provider_configurations map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no links are configured."
  }

  assert {
    condition     = length(output.links) == 0
    error_message = "links output should be empty when no links are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
