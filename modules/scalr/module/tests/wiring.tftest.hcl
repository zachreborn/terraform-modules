mock_provider "scalr" {
  mock_resource "scalr_module_namespace" {
    defaults = {
      id = "modns-mockedvalue1"
    }
  }

  mock_resource "scalr_module" {
    defaults = {
      id     = "mod-xxxxxxxxxx"
      source = "modns-mockedvalue1/aws/vpc"
      status = "active"
    }
  }
}

run "modules_namespace_key_uses_internal_namespace_id" {
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
    condition     = output.ids["vpc"] != null
    error_message = "modules entry should resolve using this module's internal wiring."
  }

  # Prove the wrapper actually passed module.namespace.ids["shared"] through as namespace_id --
  # not just that some entry landed under the expected key. "modns-mockedvalue1" is the mocked
  # scalr_module_namespace id above; a wrong or unresolved namespace_id would fail this even
  # though the != null check above would still pass.
  assert {
    condition     = output.resolved_namespace_ids["vpc"] == "modns-mockedvalue1"
    error_message = "namespace_key \"shared\" should resolve to the namespace created by this same module call, via module.namespace.ids[\"shared\"]."
  }

  assert {
    condition     = output.resolved_namespace_ids["vpc"] == output.namespace_ids["shared"]
    error_message = "The vpc module's resolved namespace_id should match the namespace actually created for the \"shared\" key."
  }
}

run "modules_accepts_external_namespace_id" {
  command = plan

  variables {
    modules = {
      legacy = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        namespace_id    = "modns-external00000"
        vcs_repo = {
          identifier = "my-org/repo"
        }
      }
    }
  }

  assert {
    condition     = output.resolved_namespace_ids["legacy"] == "modns-external00000"
    error_message = "modules entry with a literal namespace_id (no corresponding var.module_namespaces entry) should plan successfully."
  }
}
