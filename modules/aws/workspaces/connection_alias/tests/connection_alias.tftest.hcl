mock_provider "aws" {
  mock_resource "aws_workspaces_connection_alias" {
    defaults = {
      id               = "rft-8012925589"
      owner_account_id = "123456789012"
      state            = "CREATED"
    }
  }
}

run "valid_baseline_creates_alias" {
  command = plan

  variables {
    connection_aliases = {
      primary = {
        connection_string = "workspaces.example.com"
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_connection_alias.this) == 1
    error_message = "Expected exactly one connection alias to be planned."
  }

  assert {
    condition     = aws_workspaces_connection_alias.this["primary"].connection_string == "workspaces.example.com"
    error_message = "connection_string should be wired through."
  }
}

run "tags_merge_module_and_entry_tags" {
  command = plan

  variables {
    tags = {
      terraform = "true"
    }
    connection_aliases = {
      primary = {
        connection_string = "workspaces.example.com"
        tags = {
          team = "it"
        }
      }
    }
  }

  assert {
    condition     = aws_workspaces_connection_alias.this["primary"].tags["terraform"] == "true"
    error_message = "Module-level tags should be present."
  }

  assert {
    condition     = aws_workspaces_connection_alias.this["primary"].tags["team"] == "it"
    error_message = "Per-alias tags should be present."
  }
}

run "outputs_expose_keyed_maps" {
  command = plan

  variables {
    connection_aliases = {
      primary = {
        connection_string = "workspaces.example.com"
      }
    }
  }

  assert {
    condition     = output.ids["primary"] != null
    error_message = "ids output should contain the primary key."
  }

  assert {
    condition     = output.owner_account_ids["primary"] != null
    error_message = "owner_account_ids output should contain the primary key."
  }

  assert {
    condition     = output.states["primary"] != null
    error_message = "states output should contain the primary key."
  }
}
