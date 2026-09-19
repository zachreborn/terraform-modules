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

run "workspace_link_wiring_uses_internal_var_set_ids" {
  command = plan

  variables {
    var_sets = {
      shared_defaults = {
        description = "Variables shared with prod workspaces"
      }
    }
    workspace_links = {
      prod_app = {
        workspace_id = "ws-xxxxxxxxxx"
        var_set_key  = "shared_defaults"
      }
    }
  }

  assert {
    condition     = output.workspace_link_ids["prod_app"] != null
    error_message = "workspace_links entry should resolve var_set_key against this module's own var_sets output."
  }

  # Prove the wrapper actually passed module.workspace_link's var_set_id through as the mocked
  # scalr_var_set id -- not just that some entry landed under the expected key. "varset-abcd1234" is
  # the mocked scalr_var_set id above; a wrong or unresolved var_set_id would fail this even though
  # the != null check above would still pass.
  assert {
    condition     = output.workspace_links["prod_app"].var_set_id == "varset-abcd1234"
    error_message = "var_set_key \"shared_defaults\" should resolve to the var set created by this same module call's var_sets input, via scalr_var_set.this."
  }

  assert {
    condition     = output.workspace_links["prod_app"].workspace_id == "ws-xxxxxxxxxx"
    error_message = "workspace_id should be passed through unchanged to the workspace_link submodule."
  }
}

run "workspace_link_accepts_external_var_set_id" {
  command = plan

  variables {
    workspace_links = {
      legacy_app = {
        workspace_id = "ws-yyyyyyyyyy"
        var_set_id   = "varset-zzzzzzzzzz"
      }
    }
  }

  assert {
    condition     = output.workspace_links["legacy_app"].var_set_id == "varset-zzzzzzzzzz"
    error_message = "workspace_links entry with a literal var_set_id (no corresponding var.var_sets entry) should plan successfully and pass the literal ID through unchanged."
  }
}

run "multiple_var_sets_and_links_plan_together" {
  command = plan

  variables {
    var_sets = {
      shared_defaults = {}
      security_baseline = {
        name         = "security-baseline"
        environments = ["*"]
      }
    }
    workspace_links = {
      prod_app = {
        workspace_id = "ws-xxxxxxxxxx"
        var_set_key  = "shared_defaults"
      }
      security_app = {
        workspace_id = "ws-yyyyyyyyyy"
        var_set_key  = "security_baseline"
      }
    }
  }

  assert {
    condition     = length(output.ids) == 2
    error_message = "Expected 2 var sets to be planned."
  }

  assert {
    condition     = length(output.workspace_link_ids) == 2
    error_message = "Expected 2 workspace links to be planned."
  }
}
