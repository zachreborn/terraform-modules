# Wiring test for modules/scalr/hook + modules/scalr/hook/environment_link
#
# Proves that a hook's ID (module.hook.ids["notify"]) flows correctly into the
# environment_link module's hook_id argument, exercising the composition between the
# two sibling submodules the way a real caller would. See
# modules/aws/organizations/tests/wiring.tftest.hcl for the pattern this mirrors.
#
# Run offline with:
#   tofu -chdir=modules/scalr/hook init -backend=false
#   tofu -chdir=modules/scalr/hook test

mock_provider "scalr" {
  mock_resource "scalr_hook" {
    defaults = {
      id = "hook-xxxxxxxxxx"
    }
  }

  mock_resource "scalr_environment_hook" {
    defaults = {
      id = "hkenv-xxxxxxxxxx"
    }
  }
}

run "hook_id_flows_into_environment_link" {
  command = plan
  module {
    source = "./tests/wiring"
  }

  assert {
    condition     = output.hook_ids["notify"] != null
    error_message = "The hook module should plan a hook and expose its ID."
  }

  assert {
    condition     = output.environment_hook_ids["notify_prod"] != null
    error_message = "The environment_link module should plan a link using the hook module's ID."
  }

  assert {
    condition     = output.environment_hooks["notify_prod"].hook_id == output.hook_ids["notify"]
    error_message = "environment_link's hook_id should resolve to the hook module's own ids[\"notify\"] output, proving the wiring between the two submodules."
  }
}
