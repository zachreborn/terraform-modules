mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    federated_environments = {
      shared_services = {
        environment_id         = "env-xxxxxxxxxx"
        federated_environments = ["env-yyyyyyyyyy"]
      }
    }
  }

  assert {
    condition     = length(scalr_federated_environments.this) == 1
    error_message = "Expected exactly one federated_environments resource to be planned."
  }
}

run "rejects_entry_that_federates_itself" {
  command = plan

  variables {
    federated_environments = {
      shared_services = {
        environment_id         = "env-xxxxxxxxxx"
        federated_environments = ["env-xxxxxxxxxx", "env-yyyyyyyyyy"]
      }
    }
  }

  expect_failures = [var.federated_environments]
}
