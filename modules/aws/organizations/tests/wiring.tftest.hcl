mock_provider "aws" {
  mock_resource "aws_organizations_organizational_unit" {
    defaults = {
      id = "ou-abcd-11111111"
    }
  }

  mock_resource "aws_organizations_organization" {
    defaults = {
      roots = [
        {
          id           = "r-abcd1234"
          arn          = "arn:aws:organizations::123456789012:root/o-abcd1234/r-abcd1234"
          name         = "Root"
          policy_types = []
        }
      ]
    }
  }
}

run "bare_top_level_ou_defaults_to_organization_root_when_org_managed" {
  command = plan

  variables {
    organization = {
      enable_identity_center_scp    = false
      enable_leave_organization_scp = false
      enable_root_access_key_scp    = false
    }
    organizational_units = {
      workloads = {}
    }
  }

  assert {
    condition     = output.organizational_unit_ids["workloads"] != null
    error_message = "Bare top-level OU should resolve using the managed Organization's root."
  }
}

# Note: the "bare top-level OU without a managed organization" failure case is exercised by
# modules/aws/organizations/ou/tests/validation.tftest.hcl ("rejects_entry_with_neither_parent_id_nor_parent_key").
# It isn't re-tested here because the failure happens inside the nested ou module's own variable
# validation, which isn't a checkable object expect_failures can reference from this wrapper's tests.
run "account_wiring_uses_internal_organizational_unit_ids" {
  command = plan

  variables {
    organization = {
      enable_identity_center_scp    = false
      enable_leave_organization_scp = false
      enable_root_access_key_scp    = false
    }
    organizational_units = {
      workloads = {}
    }
    accounts = {
      company_ventures = {
        email      = "jdoe@example.com"
        parent_key = "workloads"
      }
    }
  }

  assert {
    condition     = output.account_ids["company_ventures"] != null
    error_message = "Account should resolve its OU parent via the wrapper's internal wiring."
  }
}

run "full_kitchen_sink_example_plans_successfully" {
  command = plan

  variables {
    organization = {
      enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY", "BACKUP_POLICY"]
      feature_set          = "ALL"
    }

    organizational_units = {
      aws_infrastructure = { parent_id = "r-n1v2" }
      cybersecurity      = { parent_id = "r-n1v2" }
      workloads          = { parent_id = "r-n1v2" }
      suspended          = { parent_id = "r-n1v2" }
      prod               = { parent_key = "workloads" }
      staging            = { parent_key = "workloads" }
      dev                = { parent_key = "workloads" }
    }

    accounts = {
      company_organization = {
        email      = "jdoe+organization@example.com"
        parent_key = "aws_infrastructure"
      }
      company_security = {
        email      = "jdoe+security@example.com"
        parent_key = "cybersecurity"
      }
      company_ventures = {
        email      = "jdoe@company.ventures"
        parent_key = "prod"
      }
    }
  }

  assert {
    condition     = length(output.organizational_unit_ids) == 7
    error_message = "Expected 7 OUs to be planned."
  }

  assert {
    condition     = length(output.account_ids) == 3
    error_message = "Expected 3 accounts to be planned."
  }
}
