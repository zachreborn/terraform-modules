mock_provider "aws" {
  mock_resource "aws_workspaces_ip_group" {
    defaults = {
      id = "wsipg-488lrtl3k"
    }
  }
}

run "valid_baseline_creates_group" {
  command = plan

  variables {
    ip_groups = {
      contractors = {
        rules = [
          { source = "203.0.113.0/24" },
        ]
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_ip_group.this) == 1
    error_message = "Expected exactly one IP group to be planned."
  }
}

run "name_defaults_to_map_key" {
  command = plan

  variables {
    ip_groups = {
      contractors = {}
    }
  }

  assert {
    condition     = aws_workspaces_ip_group.this["contractors"].name == "contractors"
    error_message = "name should default to the entry's map key when unset."
  }
}

run "name_override_is_honored" {
  command = plan

  variables {
    ip_groups = {
      contractors = {
        name = "Contractors"
      }
    }
  }

  assert {
    condition     = aws_workspaces_ip_group.this["contractors"].name == "Contractors"
    error_message = "Explicit name should override the map key default."
  }
}

run "rules_are_wired_through" {
  command = plan

  variables {
    ip_groups = {
      contractors = {
        rules = [
          { source = "203.0.113.0/24", description = "NY" },
          { source = "198.51.100.0/24", description = "LA" },
        ]
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_ip_group.this["contractors"].rules) == 2
    error_message = "Both rules should be wired through."
  }
}

run "rules_default_to_empty_list" {
  command = plan

  variables {
    ip_groups = {
      contractors = {}
    }
  }

  assert {
    condition     = length(aws_workspaces_ip_group.this["contractors"].rules) == 0
    error_message = "rules should default to an empty list."
  }
}

run "tags_merge_module_and_entry_tags" {
  command = plan

  variables {
    tags = {
      terraform = "true"
    }
    ip_groups = {
      contractors = {
        tags = {
          team = "vendors"
        }
      }
    }
  }

  assert {
    condition     = aws_workspaces_ip_group.this["contractors"].tags["terraform"] == "true"
    error_message = "Module-level tags should be present."
  }

  assert {
    condition     = aws_workspaces_ip_group.this["contractors"].tags["team"] == "vendors"
    error_message = "Per-group tags should be present."
  }
}

run "outputs_expose_keyed_map" {
  command = plan

  variables {
    ip_groups = {
      contractors = {}
    }
  }

  assert {
    condition     = output.ids["contractors"] != null
    error_message = "ids output should contain the contractors key."
  }
}
