mock_provider "scalr" {
  mock_resource "scalr_var_set" {
    defaults = {
      id = "varset-abcd1234"
    }
  }
  mock_resource "scalr_workspace_var_set" {
    defaults = {
      id = "ws-xxxxxxxxxx/varset-abcd1234"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    var_sets = {
      shared_defaults = {}
    }
  }

  assert {
    condition     = length(scalr_var_set.this) == 1
    error_message = "Expected exactly one var set to be planned."
  }
}

run "rejects_workspace_link_with_both_var_set_id_and_var_set_key" {
  command = plan

  variables {
    workspace_links = {
      prod_app = {
        workspace_id = "ws-xxxxxxxxxx"
        var_set_id   = "varset-zzzzzzzzzz"
        var_set_key  = "shared_defaults"
      }
    }
  }

  expect_failures = [var.workspace_links]
}

run "rejects_workspace_link_with_neither_var_set_id_nor_var_set_key" {
  command = plan

  variables {
    workspace_links = {
      prod_app = {
        workspace_id = "ws-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.workspace_links]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
