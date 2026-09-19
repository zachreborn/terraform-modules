mock_provider "scalr" {
  mock_resource "scalr_module" {
    defaults = {
      id     = "mod-xxxxxxxxxx"
      source = "env-xxxx/aws/vpc"
      status = "active"
    }
  }

  mock_resource "scalr_module_namespace" {
    defaults = {
      id = "modns-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_plans_a_single_module" {
  command = plan

  variables {
    modules = {
      vpc = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/terraform-aws-vpc"
        }
      }
    }
  }

  assert {
    condition     = length(scalr_module.this) == 1
    error_message = "Expected exactly one module to be planned."
  }

  assert {
    condition     = output.ids["vpc"] != null
    error_message = "Expected the ids output to contain the vpc module."
  }

  assert {
    condition     = output.sources["vpc"] == "env-xxxx/aws/vpc"
    error_message = "Expected the sources output to reflect the mocked source."
  }

  assert {
    condition     = length(output.namespace_ids) == 0
    error_message = "Expected no namespaces when module_namespaces is not set."
  }
}

run "module_namespaces_conditional_branch_creates_namespace" {
  command = plan

  variables {
    module_namespaces = {
      shared = {
        is_shared = true
      }
    }
    modules = {
      vpc = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        namespace_key   = "shared"
        vcs_repo = {
          identifier = "my-org/terraform-aws-vpc"
          path       = "."
          tag_prefix = "aws/"
        }
      }
    }
  }

  assert {
    condition     = length(output.namespace_ids) == 1
    error_message = "Expected one namespace to be planned when module_namespaces has one entry."
  }

  assert {
    condition     = output.resolved_namespace_ids["vpc"] != null
    error_message = "Expected the vpc module's resolved namespace_id to be non-null when namespace_key is set."
  }
}

run "literal_namespace_id_and_deprecated_account_id_plan_successfully" {
  command = plan

  variables {
    modules = {
      legacy = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        namespace_id    = "modns-xxxxxxxxxx"
        module_provider = "couchbasecapella"
        name            = "infra"
        account_id      = "acc-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/repo"
          path       = "example/terraform-couchbase-capella-infra"
        }
      }
    }
  }

  assert {
    condition     = output.resolved_namespace_ids["legacy"] == "modns-xxxxxxxxxx"
    error_message = "Expected the literal namespace_id to be passed through unchanged."
  }
}
