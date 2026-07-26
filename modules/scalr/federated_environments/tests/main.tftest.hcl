# scalr_federated_environments has no computed/read-only attributes in the upstream provider
# schema (environment_id and federated_environments are both required, non-computed) -- there is
# nothing for mock_resource to override, so a bare mock_provider block is sufficient here.
mock_provider "scalr" {}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    federated_environments = {
      shared_services = {
        environment_id         = "env-xxxxxxxxxx"
        federated_environments = ["env-yyyyyyyyyy", "env-zzzzzzzzzz"]
      }
    }
  }

  assert {
    condition     = length(scalr_federated_environments.this) == 1
    error_message = "Expected exactly one federated_environments resource to be planned."
  }

  assert {
    condition     = output.environment_ids["shared_services"] == "env-xxxxxxxxxx"
    error_message = "Expected the environment_ids output to reflect the configured environment_id."
  }

  assert {
    condition     = length(output.federated_environment_sets["shared_services"]) == 2
    error_message = "Expected the federated_environment_sets output to contain both federated environments."
  }
}

run "wildcard_federation_plans_successfully" {
  command = plan

  variables {
    federated_environments = {
      shared_services = {
        environment_id         = "env-xxxxxxxxxx"
        federated_environments = ["*"]
      }
    }
  }

  assert {
    condition     = contains(output.federated_environment_sets["shared_services"], "*")
    error_message = "Expected the wildcard federated_environments entry to plan successfully."
  }
}

run "empty_map_plans_with_no_resources" {
  command = plan

  variables {
    federated_environments = {}
  }

  assert {
    condition     = length(scalr_federated_environments.this) == 0
    error_message = "Expected zero federated_environments resources to be planned when the map is empty."
  }
}
