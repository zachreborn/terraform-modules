mock_provider "aws" {
  mock_resource "aws_organizations_organizational_unit" {
    defaults = {
      id = "ou-abcd-11111111"
    }
  }
}

run "top_level_ou_uses_literal_parent_id" {
  command = plan

  variables {
    organizational_units = {
      workloads = {
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = aws_organizations_organizational_unit.level_0["workloads"].parent_id == "r-abcd1234"
    error_message = "Top-level OU should use the literal parent_id."
  }
}

run "name_defaults_to_map_key" {
  command = plan

  variables {
    organizational_units = {
      workloads = {
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = aws_organizations_organizational_unit.level_0["workloads"].name == "workloads"
    error_message = "name should default to the entry's map key when unset."
  }
}

run "name_override_is_honored" {
  command = plan

  variables {
    organizational_units = {
      workloads = {
        name      = "Workloads Environment"
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = aws_organizations_organizational_unit.level_0["workloads"].name == "Workloads Environment"
    error_message = "Explicit name should override the map key default."
  }
}

run "nesting_resolves_across_levels" {
  command = plan

  variables {
    organizational_units = {
      workloads   = { parent_id = "r-abcd1234" }
      prod        = { parent_key = "workloads" }
      staging_env = { parent_key = "prod" }
      deep_env    = { parent_key = "staging_env" }
    }
  }

  assert {
    condition     = length(aws_organizations_organizational_unit.level_0) == 1
    error_message = "Expected 1 level_0 OU."
  }

  assert {
    condition     = length(aws_organizations_organizational_unit.level_1) == 1
    error_message = "Expected 1 level_1 OU."
  }

  assert {
    condition     = length(aws_organizations_organizational_unit.level_2) == 1
    error_message = "Expected 1 level_2 OU."
  }

  assert {
    condition     = length(aws_organizations_organizational_unit.level_3) == 1
    error_message = "Expected 1 level_3 OU."
  }

  assert {
    condition     = aws_organizations_organizational_unit.level_1["prod"].parent_id == aws_organizations_organizational_unit.level_0["workloads"].id
    error_message = "level_1 OU parent_id should equal the mocked id of its level_0 parent."
  }

  assert {
    condition     = aws_organizations_organizational_unit.level_2["staging_env"].parent_id == aws_organizations_organizational_unit.level_1["prod"].id
    error_message = "level_2 OU parent_id should equal the mocked id of its level_1 parent."
  }

  assert {
    condition     = aws_organizations_organizational_unit.level_3["deep_env"].parent_id == aws_organizations_organizational_unit.level_2["staging_env"].id
    error_message = "level_3 OU parent_id should equal the mocked id of its level_2 parent."
  }
}

run "tags_merge_module_and_entry_tags" {
  command = plan

  variables {
    tags = {
      terraform = "true"
      team      = "platform"
    }
    organizational_units = {
      workloads = {
        parent_id = "r-abcd1234"
        tags = {
          team = "workloads-team"
          env  = "prod"
        }
      }
    }
  }

  assert {
    condition     = aws_organizations_organizational_unit.level_0["workloads"].tags["terraform"] == "true"
    error_message = "Module-level tags should be present."
  }

  assert {
    condition     = aws_organizations_organizational_unit.level_0["workloads"].tags["team"] == "workloads-team"
    error_message = "Per-OU tags should override module-level tags with the same key."
  }

  assert {
    condition     = aws_organizations_organizational_unit.level_0["workloads"].tags["env"] == "prod"
    error_message = "Per-OU-only tag keys should be present."
  }
}

run "outputs_expose_keyed_maps" {
  command = plan

  variables {
    organizational_units = {
      workloads = { parent_id = "r-abcd1234" }
      prod      = { parent_key = "workloads" }
    }
  }

  assert {
    condition     = output.ids["workloads"] != null && output.ids["prod"] != null
    error_message = "ids output should contain both keys."
  }

  assert {
    condition     = output.arns["workloads"] != null
    error_message = "arns output should contain the workloads key."
  }

  assert {
    condition     = keys(output.accounts) == keys(var.organizational_units)
    error_message = "accounts output should be keyed the same as the input map."
  }
}

run "exceeding_max_nesting_depth_fails_ids_output" {
  command = plan

  variables {
    organizational_units = {
      level_a = { parent_id = "r-abcd1234" }
      level_b = { parent_key = "level_a" }
      level_c = { parent_key = "level_b" }
      level_d = { parent_key = "level_c" }
      level_e = { parent_key = "level_d" }
    }
  }

  expect_failures = [output.ids]
}
