mock_provider "aws" {
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

run "organization_unset_creates_no_org_resource" {
  command = plan

  variables {
    organization = null
    organizational_units = {
      workloads = {
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = output.organization == null
    error_message = "organization output should be null when var.organization is unset."
  }

  assert {
    condition     = length(module.organization) == 0
    error_message = "No organization submodule instance should be created."
  }
}

run "organization_set_creates_org_resource" {
  command = plan

  variables {
    organization = {
      enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]
    }
    organizational_units = {
      workloads = {
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = output.organization != null
    error_message = "organization output should be non-null when var.organization is set."
  }

  assert {
    condition     = output.organization.id != null
    error_message = "organization output should expose a mocked id."
  }

  assert {
    condition     = length(module.organization) == 1
    error_message = "Exactly one organization submodule instance should be created."
  }
}
