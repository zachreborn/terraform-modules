mock_provider "scalr" {
  mock_resource "scalr_tag" {
    defaults = {
      id = "tag-abcd1234"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    tags = {
      network    = {}
      compliance = { name = "pci-scope" }
      sandbox    = { account_id = "acc-xxxxxxxxxx" }
    }
  }

  assert {
    condition     = length(scalr_tag.this) == 3
    error_message = "Expected exactly three tags to be planned."
  }

  assert {
    condition     = scalr_tag.this["network"].name == "network"
    error_message = "An entry with no explicit name should default the tag name to its map key."
  }

  assert {
    condition     = scalr_tag.this["compliance"].name == "pci-scope"
    error_message = "An entry with an explicit name should use that name rather than the map key."
  }

  assert {
    condition     = scalr_tag.this["sandbox"].account_id == "acc-xxxxxxxxxx"
    error_message = "An entry's account_id should be passed through to the resource."
  }

  assert {
    condition     = output.names["network"] == "network"
    error_message = "output.names should expose the resolved (post-default) tag name."
  }
}

run "outputs_expose_every_entry" {
  command = plan

  variables {
    tags = {
      network = {}
    }
  }

  assert {
    condition     = length(output.ids) == 1
    error_message = "output.ids should contain exactly one entry."
  }

  assert {
    condition     = output.ids["network"] != null
    error_message = "output.ids should expose the mocked tag ID for the 'network' entry."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
