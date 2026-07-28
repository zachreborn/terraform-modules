# Offline test suite for the modules/scalr root module.
# All resources are mocked via mock_provider "scalr" so these tests run without any real Scalr
# credentials or backend.
#
# Since the root now composes the ./environment, ./workspace, ./vcs_provider, and
# ./provider_configuration submodules, these tests assert the composition via the root module's
# OUTPUTS. `tofu test` assertions cannot reference resources declared inside child modules, and the
# fine-grained per-resource behavior (workspace provider_configuration block set, custom argument
# secret resolution, etc.) is covered by each submodule's own tests. A workspace whose
# provider_configuration references a provider-config name that fails to resolve would error the
# plan, so a successful plan here also proves the root's name -> ID wiring.

mock_provider "scalr" {
  mock_resource "scalr_environment" {
    defaults = {
      id = "env-mock00000000"
    }
  }

  mock_resource "scalr_workspace" {
    defaults = {
      id = "ws-mock00000000"
    }
  }

  mock_resource "scalr_vcs_provider" {
    defaults = {
      id = "vcs-mock00000000"
    }
  }

  mock_resource "scalr_provider_configuration" {
    defaults = {
      id = "pcfg-mock0000000"
    }
  }

  mock_data "scalr_current_account" {
    defaults = {
      id = "acc-mock00000000"
    }
  }
}

# Baseline scalr_config equivalent to example_scalr_config.yaml:
#  - workspace-1/workspace-2 omit `vcs_repo` entirely to prove the transform tolerates a workspace
#    entry that never sets the key.
#  - `provider_configuration` is a list (the provider models it as a Block Set); `trigger_patterns`
#    is a single glob-style string per the provider schema (not a list).
variables {
  scalr_config = <<-YAML
    ---
    environment-1:
      workspaces:
        workspace-1:
          description: "This is workspace 1 in environment 1"
        workspace-2:
          description: "This is workspace 2 in environment 1"
    environment-2-all-options:
      default_provider_configurations:
        - "default-provider-1"
        - "default-provider-2"
      default_workspace_agent_pool_id: "default-agent-pool-1"
      federated_environments:
        - "federated-env-1"
        - "federated-env-2"
      mask_sensitive_output: true
      remote_backend: true
      remote_backend_overridable: false
      storage_profile_id: "storage-profile-1"
      tag_ids:
        - "tag-1"
        - "tag-2"
      workspaces:
        workspace-3-all-options:
          agent_pool_id: "agent-pool-1"
          auto_apply: false
          auto_queue_runs: "skip_first"
          deletion_protection_enabled: true
          description: "This is workspace 3 in environment 2"
          execution_mode: "remote"
          force_latest_run: false
          hooks:
            pre_init: "./scripts/pre_init.sh"
            pre_plan: "./scripts/pre_plan.sh"
            post_plan: "./scripts/post_plan.sh"
            pre_apply: "./scripts/pre_apply.sh"
            post_apply: "./scripts/post_apply.sh"
          iac_platform: "opentofu"
          remote_backend: true
          remote_state_consumers:
            - "consumer-1"
            - "consumer-2"
          run_operation_timeout: 30
          ssh_key_id: "ssh-key-1"
          tag_ids:
            - "tag-1"
            - "tag-2"
          terraform_version: "1.5.0"
          type: "development"
          var_files:
            - "var-file-1"
            - "var-file-2"
          working_directory: "/path/to/working/directory"
          provider_configuration:
            - name: "aws_provider_1"
              alias: "primary"
          vcs_provider_id: "vcs-abc0000000001"
          vcs_repo:
            branch: "main"
            dry_runs_enabled: true
            identifier: "org/repo"
            ingress_submodules: false
            trigger_patterns: "*.tf"
  YAML

  aws_provider_config = <<-YAML
    ---
    aws_provider_1:
      audience: "your_audience_client_id"
      credentials_type: "oidc"
      environments:
        - "production"
        - "staging"
      role_arn: "arn:aws:iam::123456789012:role/ScalrOIDCRole"
  YAML
}

run "valid_baseline_plans_successfully" {
  command = plan

  assert {
    condition     = length(output.environment_ids) == 2
    error_message = "Expected 2 environments to be planned."
  }

  assert {
    condition     = output.environment_ids["environment-1"] != null && output.environment_ids["environment-2-all-options"] != null
    error_message = "environment_ids should be keyed by environment name."
  }

  assert {
    condition     = length(output.workspace_ids) == 3
    error_message = "Expected 3 workspaces to be planned across both environments."
  }

  assert {
    condition = alltrue([
      contains(keys(output.workspace_ids), "environment-1.workspace-1"),
      contains(keys(output.workspace_ids), "environment-1.workspace-2"),
      contains(keys(output.workspace_ids), "environment-2-all-options.workspace-3-all-options"),
    ])
    error_message = "workspace_ids should be keyed by the '<environment>.<workspace>' composite key."
  }

  assert {
    condition     = length(output.vcs_provider_ids) == 0
    error_message = "No vcs_provider_config was supplied in this run, so vcs_provider_ids should be empty."
  }

  # provider_configuration_ids is the unified map across all provider types; only aws_provider_1
  # exists in this run.
  assert {
    condition     = length(output.provider_configuration_ids) == 1 && output.provider_configuration_ids["aws_provider_1"] != null
    error_message = "Expected exactly one provider configuration (aws_provider_1) in the unified provider_configuration_ids map."
  }

  assert {
    condition     = length(output.provider_configuration_aws_ids) == 1 && output.provider_configuration_aws_ids["aws_provider_1"] != null
    error_message = "Expected exactly one AWS provider configuration in the per-type provider_configuration_aws_ids map."
  }

  # The azurerm/google/custom per-type subsets should be empty when no such YAML was supplied.
  assert {
    condition     = length(output.provider_configuration_azurerm_ids) == 0
    error_message = "No azurerm_provider_config was supplied, so provider_configuration_azurerm_ids should be empty."
  }

  assert {
    condition     = length(output.provider_configuration_google_ids) == 0
    error_message = "No google_provider_config was supplied, so provider_configuration_google_ids should be empty."
  }

  assert {
    condition     = length(output.provider_configuration_custom_ids) == 0
    error_message = "No custom_provider_config was supplied, so provider_configuration_custom_ids should be empty."
  }
}

run "vcs_provider_config_plans_and_populates_output" {
  command = plan

  variables {
    vcs_provider_config = <<-YAML
      ---
      github-vcs:
        vcs_type: "github"
        # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
        token: "mock-vcs-token-value"
        environments:
          - "*"
    YAML
  }

  assert {
    condition     = length(output.vcs_provider_ids) == 1 && output.vcs_provider_ids["github-vcs"] != null
    error_message = "Expected exactly one VCS provider to be planned when vcs_provider_config is supplied."
  }
}

run "provider_configuration_ids_unifies_all_provider_types" {
  command = plan

  variables {
    azurerm_provider_config = <<-YAML
      ---
      azurerm_provider_1:
        auth_type: "oidc"
        audience: "api://AzureADTokenExchange"
        client_id: "00000000-0000-0000-0000-000000000000"
        tenant_id: "11111111-1111-1111-1111-111111111111"
        subscription_id: "22222222-2222-2222-2222-222222222222"
        environments:
          - "production"
          - "staging"
    YAML

    google_provider_config = <<-YAML
      ---
      google_provider_1:
        auth_type: "oidc"
        project: "my-gcp-project"
        service_account_email: "scalr@my-gcp-project.iam.gserviceaccount.com"
        workload_provider_name: "projects/123456789/locations/global/workloadIdentityPools/scalr-pool/providers/scalr-provider"
        environments:
          - "production"
        default_labels:
          strategy: "update"
          labels:
            Environment: "Production"
    YAML

    custom_provider_config = <<-YAML
      ---
      kubernetes:
        provider_name: "kubernetes"
        environments:
          - "production"
        argument:
          - name: "host"
            value: "https://kubernetes.example.com"
            description: "The hostname (in form of URI) of the Kubernetes API."
          - name: "config_path"
            value: "~/.kube/config"
            hcl: false
          - name: "password"
            sensitive: true
    YAML

    custom_argument_secrets = {
      kubernetes = {
        # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
        password = "my-k8s-password"
      }
    }
  }

  # The unified provider_configuration_ids map should now contain every provider type: the
  # baseline aws_provider_1 plus the azurerm/google/custom entries added here.
  assert {
    condition     = length(output.provider_configuration_ids) == 4
    error_message = "provider_configuration_ids should be the unified map across all four provider types."
  }

  assert {
    condition = alltrue([
      output.provider_configuration_ids["aws_provider_1"] != null,
      output.provider_configuration_ids["azurerm_provider_1"] != null,
      output.provider_configuration_ids["google_provider_1"] != null,
      output.provider_configuration_ids["kubernetes"] != null,
    ])
    error_message = "provider_configuration_ids should include the AWS, AzureRM, Google, and custom configuration names."
  }

  assert {
    condition     = length(output.provider_configuration_azurerm_ids) == 1 && output.provider_configuration_azurerm_ids["azurerm_provider_1"] != null
    error_message = "Expected exactly one AzureRM provider configuration in the per-type subset."
  }

  assert {
    condition     = length(output.provider_configuration_google_ids) == 1 && output.provider_configuration_google_ids["google_provider_1"] != null
    error_message = "Expected exactly one Google provider configuration in the per-type subset."
  }

  assert {
    condition     = length(output.provider_configuration_custom_ids) == 1 && output.provider_configuration_custom_ids["kubernetes"] != null
    error_message = "Expected exactly one custom provider configuration in the per-type subset."
  }

  # Wiring: prove the root's YAML-to-submodule transformation forwards the custom provider_name and
  # arguments correctly (the ./provider_configuration submodule's own tests cover secret-value
  # resolution; these assertions cover this wrapper's transformation, which those cannot).
  assert {
    condition     = output.provider_configuration_custom["kubernetes"].provider_name == "kubernetes"
    error_message = "The custom provider_name should be forwarded from the YAML into the ./provider_configuration submodule input."
  }

  assert {
    condition     = [for a in output.provider_configuration_custom["kubernetes"].arguments : a.value if a.name == "host"][0] == "https://kubernetes.example.com"
    error_message = "A non-sensitive custom argument's value should be forwarded from the YAML into the submodule's custom.arguments."
  }

  assert {
    condition     = [for a in output.provider_configuration_custom["kubernetes"].arguments : a.sensitive if a.name == "password"][0] == true
    error_message = "A custom argument marked sensitive in the YAML should carry sensitive=true into the submodule input (its value is routed via provider_configuration_secrets, asserted in the submodule's own tests)."
  }
}

run "workspace_provider_configuration_resolves_non_aws_provider" {
  command = plan

  variables {
    azurerm_provider_config = <<-YAML
      ---
      azurerm_provider_1:
        auth_type: "oidc"
        audience: "api://AzureADTokenExchange"
        client_id: "00000000-0000-0000-0000-000000000000"
        tenant_id: "11111111-1111-1111-1111-111111111111"
        subscription_id: "22222222-2222-2222-2222-222222222222"
    YAML

    scalr_config = <<-YAML
      ---
      environment-1:
        workspaces:
          azurerm_workspace:
            provider_configuration:
              - name: "azurerm_provider_1"
    YAML
  }

  # A successful plan proves the workspace's provider_configuration.name resolved against the merged
  # local.provider_configuration_ids lookup (not just AWS); an unresolved name would error the plan.
  assert {
    condition     = output.workspace_ids["environment-1.azurerm_workspace"] != null
    error_message = "A workspace's provider_configuration.name should resolve against the unified provider_configuration_ids lookup across all provider types."
  }
}

run "workspace_provider_configuration_supports_multiple_entries" {
  command = plan

  variables {
    aws_provider_config = <<-YAML
      ---
      aws_provider_1:
        credentials_type: "access_keys"
        access_key: "my-plan-access-key"
      aws_provider_2:
        credentials_type: "access_keys"
        access_key: "my-apply-access-key"
    YAML

    scalr_config = <<-YAML
      ---
      environment-1:
        workspaces:
          multi_provider_workspace:
            provider_configuration:
              - name: "aws_provider_1"
                alias: "us_east_1"
              - name: "aws_provider_2"
                alias: "us_east_2"
    YAML
  }

  # A successful plan proves both provider_configuration names resolved to created configurations;
  # the workspace submodule's own tests assert the Block Set actually renders two entries.
  assert {
    condition     = output.workspace_ids["environment-1.multi_provider_workspace"] != null
    error_message = "A workspace should support multiple provider_configuration entries, each resolving to a created provider configuration."
  }

  # Wiring: prove BOTH resolved entries (with their aliases and resolved IDs, in order) are forwarded
  # to the ./workspace submodule, not collapsed to one. The child module's direct-input test cannot
  # cover this wrapper's name-to-ID list transformation.
  assert {
    condition     = length(output.workspace_provider_configurations["environment-1.multi_provider_workspace"]) == 2
    error_message = "Both provider_configuration entries should be forwarded to the ./workspace submodule (not collapsed to one)."
  }

  assert {
    condition     = [for pc in output.workspace_provider_configurations["environment-1.multi_provider_workspace"] : pc.alias] == ["us_east_1", "us_east_2"]
    error_message = "Both provider_configuration aliases should be preserved, in order, when forwarded to the ./workspace submodule."
  }

  assert {
    condition     = alltrue([for pc in output.workspace_provider_configurations["environment-1.multi_provider_workspace"] : pc.id != null])
    error_message = "Each provider_configuration entry's YAML name should resolve to a created provider configuration ID."
  }
}

run "rejects_duplicate_provider_configuration_name_across_types" {
  command = plan

  variables {
    scalr_config = <<-YAML
      ---
      environment-1:
        workspaces:
          workspace-1: {}
    YAML

    aws_provider_config = <<-YAML
      ---
      shared:
        credentials_type: "access_keys"
        access_key: "my-access-key"
    YAML

    azurerm_provider_config = <<-YAML
      ---
      shared:
        auth_type: "oidc"
        audience: "api://AzureADTokenExchange"
        client_id: "00000000-0000-0000-0000-000000000000"
        tenant_id: "11111111-1111-1111-1111-111111111111"
    YAML
  }

  # "shared" is defined in both aws_provider_config and azurerm_provider_config; merge() would
  # silently drop one. The data source precondition must reject the duplicate name across types.
  expect_failures = [data.scalr_current_account.account]
}

run "aws_access_key_module_wide_fallback_plans_successfully" {
  command = plan

  variables {
    aws_provider_config = <<-YAML
      ---
      aws_provider_1:
        credentials_type: "access_keys"
    YAML

    # No per-entry access_key override -- this exercises the module-wide fallback
    # (try(cfg.access_key, var.aws_access_key)) with the sensitive aws_access_key variable, which
    # must not taint local.provider_configurations in a way that breaks the composed
    # ./provider_configuration submodule's for_each (for_each only requires known, non-sensitive
    # map KEYS -- a sensitive leaf attribute value does not prevent it).
    aws_access_key = "my-module-wide-fallback-key"
  }

  assert {
    condition     = output.provider_configuration_ids["aws_provider_1"] != null
    error_message = "A provider configuration relying solely on the module-wide aws_access_key fallback should plan successfully."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails, treat it
# as a signal that the module code has a bug and fix the root cause in main.tf / variables.tf /
# outputs.tf, then re-run `tofu test` until it passes for the right reason.
