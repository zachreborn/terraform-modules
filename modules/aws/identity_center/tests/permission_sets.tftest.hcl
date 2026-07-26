# Native OpenTofu tests for modules/aws/identity_center's permission_sets composition.
#
# The "group_keys_wiring_creates_group_and_permission_set_together" run is the direct regression proof
# for issue #456 at the composed-module level: a brand-new group (var.groups) and a permission_sets
# entry referencing it via group_keys plan successfully together, in one apply, because group_keys
# resolves through a resource attribute (aws_identitystore_group.this[key].group_id) rather than the
# permission_set submodule's own name-based data source lookup.
#
# Run offline with:
#   tofu -chdir=modules/aws/identity_center init -backend=false
#   tofu -chdir=modules/aws/identity_center test

mock_provider "aws" {
  mock_data "aws_ssoadmin_instances" {
    defaults = {
      identity_store_ids = ["d-1234567890"]
      arns               = ["arn:aws:sso:::instance/ssoins-1234567890abcdef"]
    }
  }

  # Deliberately DIFFERENT from the mock_resource group_id below, so assertions can distinguish
  # "resolved via this data source" (permission_set submodule's name-based groups lookup) from
  # "resolved via the resource attribute" (this parent module's own group_keys wiring).
  mock_data "aws_identitystore_group" {
    defaults = {
      group_id = "22222222-2222-2222-2222-222222222222"
    }
  }

  # aws_identitystore_group is also a real RESOURCE in this parent module (var.groups), distinct from
  # the permission_set submodule's data-source lookup of the same type name mocked above.
  mock_resource "aws_identitystore_group" {
    defaults = {
      group_id = "11111111-1111-1111-1111-111111111111"
    }
  }

  mock_resource "aws_ssoadmin_permission_set" {
    defaults = {
      arn          = "arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890"
      created_date = "2024-01-01T00:00:00Z"
      id           = "arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890"
    }
  }

  mock_resource "aws_ssoadmin_account_assignment" {
    defaults = {
      id = "94481408-a061-70b9-9ae4-163731112222,GROUP,123456789012,AWS_ACCOUNT,arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890,arn:aws:sso:::instance/ssoins-1234567890abcdef"
    }
  }
}

run "empty_permission_sets_creates_no_instances" {
  command = plan

  variables {
    groups = {}
    users  = {}
  }

  # permission_sets is intentionally left unset; exercises the default = {} branch.

  assert {
    condition     = length(module.permission_sets) == 0
    error_message = "An empty permission_sets map should create no permission_set submodule instances."
  }

  assert {
    condition     = length(output.permission_set_ids) == 0
    error_message = "permission_set_ids should be empty when no permission_sets are configured."
  }
}

run "group_keys_wiring_creates_group_and_permission_set_together" {
  command = plan

  variables {
    groups = {
      Administrators = {
        display_name = "Administrators"
      }
    }
    users = {}
    permission_sets = {
      admins = {
        group_keys      = ["Administrators"]
        target_accounts = ["123456789012"]
      }
    }
  }

  assert {
    condition     = module.permission_sets["admins"].id != null
    error_message = "The permission set should plan successfully when its group is created in the same apply via group_keys."
  }

  assert {
    condition     = output.permission_set_group_ids["admins"]["Administrators"] == aws_identitystore_group.this["Administrators"].group_id
    error_message = "The permission set's resolved group ID should exactly match this module's own newly-created group resource, proving the wiring is a direct resource-attribute reference."
  }

  assert {
    condition     = output.permission_set_group_ids["admins"]["Administrators"] == "11111111-1111-1111-1111-111111111111"
    error_message = "group_keys should resolve via the resource-mocked group ID, never the permission_set submodule's own data source lookup -- this is the issue #456 regression proof."
  }
}

run "groups_by_name_branch_uses_data_source" {
  command = plan

  variables {
    groups = {}
    users  = {}
    permission_sets = {
      readonly = {
        groups          = ["pre-existing-group"]
        target_accounts = ["123456789012"]
      }
    }
  }

  assert {
    condition     = output.permission_set_group_ids["readonly"]["pre-existing-group"] == "22222222-2222-2222-2222-222222222222"
    error_message = "A permission_sets entry using groups (by display name) should resolve via the permission_set submodule's own data source (the data-source-mocked group ID), not this module's group resources."
  }
}

run "mixed_groups_and_group_keys" {
  command = plan

  variables {
    groups = {
      Administrators = {
        display_name = "Administrators"
      }
    }
    users = {}
    permission_sets = {
      mixed = {
        groups          = ["pre-existing-group"]
        group_keys      = ["Administrators"]
        target_accounts = ["123456789012"]
      }
    }
  }

  assert {
    condition     = length(output.permission_set_group_ids["mixed"]) == 2
    error_message = "The permission set should resolve both the name-based group and the group_keys-based group."
  }

  assert {
    condition     = output.permission_set_group_ids["mixed"]["pre-existing-group"] == "22222222-2222-2222-2222-222222222222"
    error_message = "The name-based groups entry should resolve via the data source (data-source-mocked ID)."
  }

  assert {
    condition     = output.permission_set_group_ids["mixed"]["Administrators"] == "11111111-1111-1111-1111-111111111111"
    error_message = "The group_keys entry should resolve via this module's own group resource (resource-mocked ID), bypassing the data source."
  }
}

run "rejects_group_keys_entry_not_found_in_groups" {
  command = plan

  variables {
    groups = {
      Administrators = {
        display_name = "Administrators"
      }
    }
    users = {}
    permission_sets = {
      broken = {
        group_keys      = ["DoesNotExist"]
        target_accounts = ["123456789012"]
      }
    }
  }

  expect_failures = [output.permission_set_resolved_group_keys]
}

run "large_permission_sets_map_scales" {
  command = plan

  variables {
    groups = { for i in range(30) : format("group-%02d", i) => { display_name = format("group-%02d", i) } }
    users  = {}
    permission_sets = {
      for i in range(30) : format("ps-%02d", i) => {
        group_keys      = [format("group-%02d", i)]
        target_accounts = [for j in range(3) : format("1000000000%02d", j)]
      }
    }
  }

  assert {
    condition     = length(module.permission_sets) == 30
    error_message = "Expected 30 permission_set submodule instances, one per permission_sets entry."
  }

  assert {
    condition     = length(output.permission_set_ids) == 30
    error_message = "permission_set_ids should contain all 30 entries."
  }

  assert {
    condition = alltrue([
      for i in range(30) : output.permission_set_group_ids[format("ps-%02d", i)][format("group-%02d", i)] == "11111111-1111-1111-1111-111111111111"
    ])
    error_message = "All 30 permission sets should resolve their group via group_keys (the resource-mocked ID), even at scale -- no data source lookups involved."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a signal that the
# module code has a bug and fix the root cause in main.tf / variables.tf / outputs.tf, then re-run
# `tofu test` until it passes for the right reason.
