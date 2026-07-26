mock_provider "scalr" {
  mock_resource "scalr_module_namespace" {
    defaults = {
      id = "modns-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    module_namespaces = {
      shared = {
        is_shared = true
      }
    }
  }

  assert {
    condition     = length(scalr_module_namespace.this) == 1
    error_message = "Expected exactly one module namespace to be planned."
  }

  assert {
    condition     = output.ids["shared"] != null
    error_message = "Expected the ids output to contain the shared namespace."
  }
}

run "empty_map_plans_with_no_namespaces" {
  command = plan

  variables {
    module_namespaces = {}
  }

  assert {
    condition     = length(scalr_module_namespace.this) == 0
    error_message = "Expected zero module namespaces to be planned when module_namespaces is empty."
  }
}

run "explicit_name_overrides_map_key" {
  command = plan

  variables {
    module_namespaces = {
      shared = {
        name         = "custom-name"
        environments = ["env-xxxxxxxxxx"]
        owners       = ["team-xxxxxxxxxx"]
      }
    }
  }

  assert {
    condition     = scalr_module_namespace.this["shared"].name == "custom-name"
    error_message = "Expected the explicit name to override the map key."
  }
}
