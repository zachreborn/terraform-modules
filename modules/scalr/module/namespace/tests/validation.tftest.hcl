mock_provider "scalr" {
  mock_resource "scalr_module_namespace" {
    defaults = {
      id = "modns-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_does_not_fail" {
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
}

run "rejects_module_namespaces_entry_with_empty_resolved_name" {
  command = plan

  variables {
    module_namespaces = {
      "" = {
        is_shared = true
      }
    }
  }

  expect_failures = [var.module_namespaces]
}
