mock_provider "scalr" {
  mock_resource "scalr_policy_group" {
    defaults = {
      id     = "pgrp-mockedvalue01"
      status = "active"
    }
  }

  mock_resource "scalr_policy_group_linkage" {
    defaults = {
      id = "pgrp-mockedvalue01/env-yyyyyyyyyyyyyyy"
    }
  }
}

run "policy_group_linkages_uses_internal_policy_group_id" {
  command = plan

  variables {
    policy_groups = {
      instance_types = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
    policy_group_linkages = {
      instance_types_prod = {
        policy_group_key = "instance_types"
        environment_id   = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = output.linkage_ids["instance_types_prod"] != null
    error_message = "policy_group_linkages entry should resolve using this module's internal wiring."
  }

  # Prove the wrapper actually passed scalr_policy_group.this["instance_types"].id through to the
  # linkage submodule -- not just that some entry landed under the expected key. "pgrp-mockedvalue01"
  # is the mocked scalr_policy_group id above; a wrong or unresolved policy_group_id would fail this
  # even though the != null check above would still pass.
  assert {
    condition     = output.resolved_linkages["instance_types_prod"].policy_group_id == "pgrp-mockedvalue01"
    error_message = "policy_group_key \"instance_types\" should resolve to the policy group created by this same module call, via scalr_policy_group.this[...].id."
  }

  assert {
    condition     = output.resolved_linkages["instance_types_prod"].policy_group_id == scalr_policy_group.this["instance_types"].id
    error_message = "The resolved_linkages output should match the policy group actually created for the instance_types key."
  }
}

run "policy_group_linkages_accepts_external_policy_group_id" {
  command = plan

  variables {
    policy_group_linkages = {
      external = {
        policy_group_id = "pgrp-external0000"
        environment_id  = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = output.linkage_ids["external"] != null
    error_message = "policy_group_linkages entry with a literal policy_group_id (no corresponding var.policy_groups entry) should plan successfully."
  }
}
