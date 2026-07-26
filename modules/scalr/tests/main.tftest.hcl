# Offline test suite for the modules/scalr root module.
# All resources are mocked via mock_provider "scalr" so these tests run without
# any real Scalr credentials or backend.

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

# Baseline scalr_config equivalent to example_scalr_config.yaml, matching the actual
# scalr_workspace resource schema:
#  - workspace-1/workspace-2 omit `vcs_repo` entirely (as example_scalr_config.yaml does)
#    to prove the `vcs_repo` dynamic block's for_each -- guarded with `try()` -- tolerates
#    a workspace entry that never sets the key, not just one that sets it to `null`.
#  - `vcs_repo` and `provider_configuration` are single objects (matching the
#    `.branch`/`.identifier`/`.name`/`.alias` attribute access in main.tf's
#    content blocks), since the resource's `provider_configuration` is only wired up
#    as a single block per workspace in this module today.
#  - `trigger_patterns` is a single glob-style string per the provider schema
#    (not a list).
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
            name: "aws_provider_1"
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

  assert {
    condition     = length(output.provider_configuration_ids) == 1 && output.provider_configuration_ids["aws_provider_1"] != null
    error_message = "Expected exactly one AWS provider configuration to be planned."
  }

  assert {
    condition     = length(scalr_workspace.this["environment-2-all-options.workspace-3-all-options"].provider_configuration) == 1
    error_message = "The provider_configuration dynamic block should be populated for workspace-3-all-options."
  }

  assert {
    condition     = length(scalr_workspace.this["environment-1.workspace-1"].provider_configuration) == 0
    error_message = "The provider_configuration dynamic block should be empty for workspaces that don't set it."
  }

  # azurerm/google/custom provider config YAML was not supplied in this run, exercising
  # the "off" side of the for_each conditional for each of the new resources.
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

run "azurerm_google_custom_provider_configurations_plan" {
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

  assert {
    condition     = length(output.provider_configuration_azurerm_ids) == 1 && output.provider_configuration_azurerm_ids["azurerm_provider_1"] != null
    error_message = "Expected exactly one AzureRM provider configuration to be planned."
  }

  assert {
    condition     = length(output.provider_configuration_google_ids) == 1 && output.provider_configuration_google_ids["google_provider_1"] != null
    error_message = "Expected exactly one Google provider configuration to be planned."
  }

  assert {
    condition     = length(output.provider_configuration_custom_ids) == 1 && output.provider_configuration_custom_ids["kubernetes"] != null
    error_message = "Expected exactly one custom provider configuration to be planned."
  }

  assert {
    condition     = scalr_provider_configuration.custom["kubernetes"].custom[0].provider_name == "kubernetes"
    error_message = "The custom provider configuration's provider_name should be wired through from the YAML."
  }

  assert {
    condition     = [for a in scalr_provider_configuration.custom["kubernetes"].custom[0].argument : a.value if a.name == "password"][0] == "my-k8s-password"
    error_message = "A sensitive custom argument's value should resolve from var.custom_argument_secrets, keyed by the provider configuration name and argument name."
  }

  assert {
    condition     = [for a in scalr_provider_configuration.custom["kubernetes"].custom[0].argument : a.value if a.name == "host"][0] == "https://kubernetes.example.com"
    error_message = "A non-sensitive custom argument's value should still come from the YAML directly."
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
              name: "azurerm_provider_1"
    YAML
  }

  assert {
    condition     = length(scalr_workspace.this["environment-1.azurerm_workspace"].provider_configuration) == 1
    error_message = "A workspace's provider_configuration.name should resolve against the merged local.provider_configuration_ids lookup, not just scalr_provider_configuration.aws."
  }
}
