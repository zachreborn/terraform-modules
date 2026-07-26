mock_provider "scalr" {
  mock_resource "scalr_provider_configuration_default" {
    defaults = {
      id = "env-xxxxxxxxxx/pcfg-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    provider_configuration_defaults = {
      aws_prod = {
        environment_id            = "env-xxxxxxxxxx"
        provider_configuration_id = "pcfg-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_provider_configuration_default.this) == 1
    error_message = "Expected exactly one provider configuration default to be planned."
  }

  assert {
    condition     = output.ids["aws_prod"] != null
    error_message = "Expected the ids output to contain the aws_prod default."
  }
}

run "empty_map_plans_with_no_defaults" {
  command = plan

  variables {
    provider_configuration_defaults = {}
  }

  assert {
    condition     = length(scalr_provider_configuration_default.this) == 0
    error_message = "Expected zero provider configuration defaults to be planned when the map is empty."
  }
}
