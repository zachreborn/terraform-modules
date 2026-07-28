<!-- Blank module readme template: Do a search and replace with your text editor for the following: `module_name`, `module_description` -->
<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">scalr</h3>
  <p align="center">
    Terraform module for managing Scalr resources. This module allows you to create and manage Scalr Environments, Workspaces, and Provider Configurations using Terraform.
    <br />
    <a href="https://github.com/zachreborn/terraform-modules"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://zacharyhill.co">Zachary Hill</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Report Bug</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#Resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

This example demonstrates how to use the `scalr` module to create Scalr environments and workspaces with a basic AWS provider configuration.

```
module "scalr" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr"
  aws_provider_config = file("${path.module}/aws_provider_config.yaml")
  scalr_config = file("${path.module}/scalr_config.yaml")
  vcs_provider_name = "GitHub"
  vcs_provider_id = "vcs-1234567890"
}
```

### Scalr Configuration Example

This is an example of the YAML formatted file defining two Scalr environments with multiple workspaces and various configuration options.

```yaml
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
      auto_queue_runs: "skip_first" # possible values: "always", "never", "skip_first", "on_create_only"
      deletion_protection_enabled: true
      description: "This is workspace 3 in environment 2"
      execution_mode: "remote" # possible values: "local", "remote"
      force_latest_run: false
      hooks:
        pre_init: "./scripts/pre_init.sh"
        pre_plan: "./scripts/pre_plan.sh"
        post_plan: "./scripts/post_plan.sh"
        pre_apply: "./scripts/pre_apply.sh"
        post_apply: "./scripts/post_apply.sh"
      iac_platform: "opentofu" # possible values: "terraform", "opentofu"
      module_version_id: "module-version-1"
      # provider_configuration is a list -- the provider supports multiple entries per
      # workspace, including two sharing the same alias for plan/apply-only use.
      provider_configuration:
        - name: "aws_provider_1"
          alias: "primary"
      remote_backend: true
      remote_state_consumers:
        - "consumer-1"
        - "consumer-2"
      run_operation_timeout: 30 # in minutes
      ssh_key_id: "ssh-key-1"
      tag_ids:
        - "tag-1"
        - "tag-2"
      terraform_version: "1.5.0"
      type: "development" # possible values: "development", "production", "staging", "testing", "unmapped"
      var_files:
        - "var-file-1"
        - "var-file-2"
      working_directory: "/path/to/working/directory"
      vcs_repo:
        branch: "main"
        dry_runs_enabled: true
        identifier: "org/repo"
        ingress_submodules: false
        trigger_patterns: "*.tf" # conflicts with trigger_prefixes; a single glob-style string, not a list
```

### AWS Provider Configuration Example

This is an example of the YAML formatted file defining an AWS provider configuration to be used with the module. It configures a single AWS provider using an OIDC identity provider and trusted role within AWS for the specified Scalr environments.

```yaml
---
aws_provider_1:
  audience: "your_audience_client_id"
  credentials_type: "oidc"
  environments:
    - "production"
    - "staging"
  role_arn: "arn:aws:iam::123456789012:role/ScalrOIDCRole"
```

### AzureRM, Google, and Custom Provider Configurations

In addition to `aws_provider_config`, the module accepts `azurerm_provider_config`, `google_provider_config`, and `custom_provider_config` -- YAML formatted files defining one or more `scalr_provider_configuration` resources for those provider types, following the exact same `<name>: { ... }` map shape as `aws_provider_config`. Each of the corresponding `azurerm_*`, `google_*`, and `custom_*` input variables (e.g. `azurerm_client_id`, `google_project`, `custom_provider_name`) sets a module-wide default that individual entries in the YAML file can override, mirroring the existing `aws_*` variables.

```yaml
# azurerm_provider_config
---
azurerm_provider_1:
  auth_type: "oidc"
  audience: "api://AzureADTokenExchange"
  client_id: "00000000-0000-0000-0000-000000000000"
  tenant_id: "11111111-1111-1111-1111-111111111111"
  subscription_id: "22222222-2222-2222-2222-222222222222"
  environments:
    - "env-xxxxxxxxxx"
    - "env-yyyyyyyyyy"
```

```yaml
# google_provider_config
---
google_provider_1:
  auth_type: "oidc"
  project: "my-gcp-project"
  service_account_email: "scalr@my-gcp-project.iam.gserviceaccount.com"
  workload_provider_name: "projects/123456789/locations/global/workloadIdentityPools/scalr-pool/providers/scalr-provider"
  environments:
    - "env-xxxxxxxxxx"
```

```yaml
# custom_provider_config
---
kubernetes:
  provider_name: "kubernetes"
  environments:
    - "env-xxxxxxxxxx"
  argument:
    - name: "host"
      value: "https://kubernetes.example.com"
      description: "The hostname (in form of URI) of the Kubernetes API."
    - name: "config_path"
      value: "~/.kube/config"
      hcl: false
```

See `example_azurerm_provider_config.yaml`, `example_google_provider_config.yaml`, and `example_custom_provider_config.yaml` in this directory for the full, ready-to-use files.

### Outputs

The module exposes `environment_ids`, `workspace_ids`, `vcs_provider_ids`, `provider_configuration_ids` (AWS), `provider_configuration_azurerm_ids`, `provider_configuration_google_ids`, and `provider_configuration_custom_ids` -- maps of the YAML-defined name (or, for `workspace_ids`, the `<environment>.<workspace>` composite key) to the corresponding Scalr resource ID.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.17.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_environment.this | resource |
| scalr_provider_configuration.aws | resource |
| scalr_provider_configuration.azurerm | resource |
| scalr_provider_configuration.custom | resource |
| scalr_provider_configuration.google | resource |
| scalr_vcs_provider.this | resource |
| scalr_workspace.this | resource |
| scalr_current_account.account | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | The AWS access key. | `string` | `null` | no |
| <a name="input_aws_account_type"></a> [aws\_account\_type](#input\_aws\_account\_type) | The type of AWS account. Valid values are 'regular', 'gov-cloud', and 'cn-cloud'. | `string` | `"regular"` | no |
| <a name="input_aws_audience"></a> [aws\_audience](#input\_aws\_audience) | The audience for the AWS credentials. Required if credentials\_type is set to 'oidc'. | `string` | `null` | no |
| <a name="input_aws_credentials_type"></a> [aws\_credentials\_type](#input\_aws\_credentials\_type) | The type of AWS credentials. Valid values are 'access\_keys', 'oidc', and 'role\_delegation'. | `string` | `"oidc"` | no |
| <a name="input_aws_environments"></a> [aws\_environments](#input\_aws\_environments) | List of Scalr Environments which the provider will be shared to. | `list(string)` | `null` | no |
| <a name="input_aws_export_shell_variables"></a> [aws\_export\_shell\_variables](#input\_aws\_export\_shell\_variables) | Whether to export provider credentials as shell variables when using the Scalr CLI with the aws provider configuration. | `bool` | `false` | no |
| <a name="input_aws_external_id"></a> [aws\_external\_id](#input\_aws\_external\_id) | The external ID to use when assuming the role. Required if aws\_credentials\_type is set to 'role\_delegation' and the role requires an external ID. | `string` | `null` | no |
| <a name="input_aws_owners"></a> [aws\_owners](#input\_aws\_owners) | List of Scalr User IDs who will own the Provider Configuration. | `list(string)` | `null` | no |
| <a name="input_aws_provider_config"></a> [aws\_provider\_config](#input\_aws\_provider\_config) | YAML formatted file defining one or more AWS provider configurations. | `string` | `null` | no |
| <a name="input_aws_role_arn"></a> [aws\_role\_arn](#input\_aws\_role\_arn) | The ARN of the role to assume. Required if aws\_credentials\_type is set to 'oidc' or 'role\_delegation'. | `string` | `null` | no |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | The AWS secret key. | `string` | `null` | no |
| <a name="input_aws_trusted_entity_type"></a> [aws\_trusted\_entity\_type](#input\_aws\_trusted\_entity\_type) | The type of trusted entity for the role. Valid values are 'aws\_account' and 'aws\_service'. | `string` | `null` | no |
| <a name="input_azurerm_audience"></a> [azurerm\_audience](#input\_azurerm\_audience) | The value of the 'aud' claim for the identity token. Required if azurerm\_auth\_type is set to 'oidc'. | `string` | `null` | no |
| <a name="input_azurerm_auth_type"></a> [azurerm\_auth\_type](#input\_azurerm\_auth\_type) | Authentication type for the AzureRM provider configuration. Valid values are 'client-secrets' and 'oidc'. | `string` | `"client-secrets"` | no |
| <a name="input_azurerm_client_id"></a> [azurerm\_client\_id](#input\_azurerm\_client\_id) | The Client ID that should be used for the AzureRM provider configuration. | `string` | `null` | no |
| <a name="input_azurerm_client_secret"></a> [azurerm\_client\_secret](#input\_azurerm\_client\_secret) | The Client Secret that should be used for the AzureRM provider configuration. Required when azurerm\_auth\_type is 'client-secrets'. | `string` | `null` | no |
| <a name="input_azurerm_environments"></a> [azurerm\_environments](#input\_azurerm\_environments) | List of Scalr Environments which the AzureRM provider configuration will be shared to. | `list(string)` | `null` | no |
| <a name="input_azurerm_export_shell_variables"></a> [azurerm\_export\_shell\_variables](#input\_azurerm\_export\_shell\_variables) | Whether to export provider credentials as shell variables when using the Scalr CLI with the AzureRM provider configuration. | `bool` | `false` | no |
| <a name="input_azurerm_owners"></a> [azurerm\_owners](#input\_azurerm\_owners) | List of Scalr Team IDs who will own the AzureRM Provider Configuration. | `list(string)` | `null` | no |
| <a name="input_azurerm_provider_config"></a> [azurerm\_provider\_config](#input\_azurerm\_provider\_config) | YAML formatted file defining one or more AzureRM provider configurations. | `string` | `null` | no |
| <a name="input_azurerm_subscription_id"></a> [azurerm\_subscription\_id](#input\_azurerm\_subscription\_id) | The Subscription ID that should be used for the AzureRM provider configuration. If omitted, it must be set as a shell variable in the workspace or as part of the source configuration. | `string` | `null` | no |
| <a name="input_azurerm_tag_ids"></a> [azurerm\_tag\_ids](#input\_azurerm\_tag\_ids) | List of Tag IDs to assign to the AzureRM Provider Configuration. | `list(string)` | `null` | no |
| <a name="input_azurerm_tenant_id"></a> [azurerm\_tenant\_id](#input\_azurerm\_tenant\_id) | The Tenant ID that should be used for the AzureRM provider configuration. | `string` | `null` | no |
| <a name="input_custom_argument"></a> [custom\_argument](#input\_custom\_argument) | List of argument blocks defining the configuration for a custom provider. Each argument requires a 'name' and may include 'value', 'description', 'hcl', and 'sensitive'. Can be overridden per provider configuration in the YAML file. When an argument's 'sensitive' is true, its 'value' here is ignored -- supply the real value via var.custom\_argument\_secrets instead. | <pre>list(object({<br/>    name        = string<br/>    value       = optional(string)<br/>    description = optional(string)<br/>    hcl         = optional(bool, false)<br/>    sensitive   = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_custom_argument_secrets"></a> [custom\_argument\_secrets](#input\_custom\_argument\_secrets) | Map of sensitive custom provider argument values, keyed by the provider configuration's name<br/>(a top-level key in custom\_provider\_config, or the resource's own name for module-wide<br/>defaults) and then by argument name. Populate an entry here instead of setting 'value' directly<br/>in custom\_argument or the YAML file whenever an argument sets 'sensitive = true': the<br/>provider's sensitive flag only controls masking in Scalr and does not prevent the value from<br/>appearing in Terraform/OpenTofu plan output when sourced from a non-sensitive variable.<br/><br/>Example:<br/>  custom\_argument\_secrets = {<br/>    kubernetes = {<br/>      password = "<value-from-a-secret-manager>"<br/>    }<br/>  } | `map(map(string))` | `{}` | no |
| <a name="input_custom_environments"></a> [custom\_environments](#input\_custom\_environments) | List of Scalr Environments which the custom provider configuration will be shared to. | `list(string)` | `null` | no |
| <a name="input_custom_export_shell_variables"></a> [custom\_export\_shell\_variables](#input\_custom\_export\_shell\_variables) | Whether to export provider credentials as shell variables when using the Scalr CLI with the custom provider configuration. | `bool` | `false` | no |
| <a name="input_custom_owners"></a> [custom\_owners](#input\_custom\_owners) | List of Scalr Team IDs who will own the custom Provider Configuration. | `list(string)` | `null` | no |
| <a name="input_custom_provider_config"></a> [custom\_provider\_config](#input\_custom\_provider\_config) | YAML formatted file defining one or more custom provider configurations. | `string` | `null` | no |
| <a name="input_custom_provider_name"></a> [custom\_provider\_name](#input\_custom\_provider\_name) | The name of the Terraform provider being configured (e.g. 'kubernetes'). Can be overridden per provider configuration in the YAML file. | `string` | `null` | no |
| <a name="input_custom_tag_ids"></a> [custom\_tag\_ids](#input\_custom\_tag\_ids) | List of Tag IDs to assign to the custom Provider Configuration. | `list(string)` | `null` | no |
| <a name="input_environment_default_provider_configurations"></a> [environment\_default\_provider\_configurations](#input\_environment\_default\_provider\_configurations) | List of Provider Configuration IDs to set as the default in the Environment. | `list(string)` | `null` | no |
| <a name="input_environment_default_workspace_agent_pool_id"></a> [environment\_default\_workspace\_agent\_pool\_id](#input\_environment\_default\_workspace\_agent\_pool\_id) | The default Agent Pool ID to assign to Workspaces in the Environment. | `string` | `null` | no |
| <a name="input_environment_federated_environments"></a> [environment\_federated\_environments](#input\_environment\_federated\_environments) | List of Environment IDs to federate with this Environment. | `list(string)` | `null` | no |
| <a name="input_environment_mask_sensitive_output"></a> [environment\_mask\_sensitive\_output](#input\_environment\_mask\_sensitive\_output) | Whether to mask sensitive output values in the Environment. | `bool` | `true` | no |
| <a name="input_environment_remote_backend"></a> [environment\_remote\_backend](#input\_environment\_remote\_backend) | Whether Scalr manages the remote backend configuration for the Environment. | `bool` | `true` | no |
| <a name="input_environment_remote_backend_overridable"></a> [environment\_remote\_backend\_overridable](#input\_environment\_remote\_backend\_overridable) | Whether Workspaces in the Environment can override the remote backend configuration. | `bool` | `false` | no |
| <a name="input_environment_storage_profile_id"></a> [environment\_storage\_profile\_id](#input\_environment\_storage\_profile\_id) | The Storage Profile ID to use for the Environment. | `string` | `null` | no |
| <a name="input_environment_tag_ids"></a> [environment\_tag\_ids](#input\_environment\_tag\_ids) | List of Tag IDs to assign to the Environment. | `list(string)` | `null` | no |
| <a name="input_google_auth_type"></a> [google\_auth\_type](#input\_google\_auth\_type) | Authentication type for the Google provider configuration. Valid values are 'service-account-key' and 'oidc'. | `string` | `"service-account-key"` | no |
| <a name="input_google_credentials"></a> [google\_credentials](#input\_google\_credentials) | Service account key file in JSON format for the Google provider configuration. Required when google\_auth\_type is 'service-account-key'. | `string` | `null` | no |
| <a name="input_google_default_labels_labels"></a> [google\_default\_labels\_labels](#input\_google\_default\_labels\_labels) | Default labels to be applied to all resources created by the Google provider configuration. | `map(string)` | `null` | no |
| <a name="input_google_default_labels_strategy"></a> [google\_default\_labels\_strategy](#input\_google\_default\_labels\_strategy) | On duplicate key behaviour for default labels. Valid values are 'skip' and 'update'. | `string` | `null` | no |
| <a name="input_google_environments"></a> [google\_environments](#input\_google\_environments) | List of Scalr Environments which the Google provider configuration will be shared to. | `list(string)` | `null` | no |
| <a name="input_google_export_shell_variables"></a> [google\_export\_shell\_variables](#input\_google\_export\_shell\_variables) | Whether to export provider credentials as shell variables when using the Scalr CLI with the Google provider configuration. | `bool` | `false` | no |
| <a name="input_google_owners"></a> [google\_owners](#input\_google\_owners) | List of Scalr Team IDs who will own the Google Provider Configuration. | `list(string)` | `null` | no |
| <a name="input_google_project"></a> [google\_project](#input\_google\_project) | The default Google Cloud project ID to manage resources in. If another project ID is specified on a resource, it will take precedence. | `string` | `null` | no |
| <a name="input_google_provider_config"></a> [google\_provider\_config](#input\_google\_provider\_config) | YAML formatted file defining one or more Google provider configurations. | `string` | `null` | no |
| <a name="input_google_service_account_email"></a> [google\_service\_account\_email](#input\_google\_service\_account\_email) | The service account email used to authenticate to GCP. Required when google\_auth\_type is 'oidc'. | `string` | `null` | no |
| <a name="input_google_tag_ids"></a> [google\_tag\_ids](#input\_google\_tag\_ids) | List of Tag IDs to assign to the Google Provider Configuration. | `list(string)` | `null` | no |
| <a name="input_google_use_default_project"></a> [google\_use\_default\_project](#input\_google\_use\_default\_project) | Whether the project a credential is created in will be used by default. | `bool` | `null` | no |
| <a name="input_google_workload_provider_name"></a> [google\_workload\_provider\_name](#input\_google\_workload\_provider\_name) | The canonical name of the workload identity provider. Required when google\_auth\_type is 'oidc'. | `string` | `null` | no |
| <a name="input_scalr_config"></a> [scalr\_config](#input\_scalr\_config) | YAML formatted file defining Scalr environments and their workspaces. | `string` | n/a | yes |
| <a name="input_vcs_provider_agent_pool_id"></a> [vcs\_provider\_agent\_pool\_id](#input\_vcs\_provider\_agent\_pool\_id) | The Agent Pool ID to assign to the VCS Provider. | `string` | `null` | no |
| <a name="input_vcs_provider_config"></a> [vcs\_provider\_config](#input\_vcs\_provider\_config) | YAML formatted file defining one or more VCS provider configurations. | `string` | `null` | no |
| <a name="input_vcs_provider_draft_pr_runs_enabled"></a> [vcs\_provider\_draft\_pr\_runs\_enabled](#input\_vcs\_provider\_draft\_pr\_runs\_enabled) | Whether draft PR runs are enabled for the VCS Provider. | `bool` | `false` | no |
| <a name="input_vcs_provider_environments"></a> [vcs\_provider\_environments](#input\_vcs\_provider\_environments) | List of Scalr Environments which the VCS Provider will be shared to. | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_vcs_provider_id"></a> [vcs\_provider\_id](#input\_vcs\_provider\_id) | The VCS Provider ID to use for the workspace. Can be overridden per workspace in the YAML file. | `string` | `null` | no |
| <a name="input_vcs_provider_token"></a> [vcs\_provider\_token](#input\_vcs\_provider\_token) | The api key or personal access token for the VCS Provider. | `string` | `null` | no |
| <a name="input_vcs_provider_url"></a> [vcs\_provider\_url](#input\_vcs\_provider\_url) | The URL of the VCS Provider. Required when using a self-hosted vcs provider. | `string` | `null` | no |
| <a name="input_vcs_provider_username"></a> [vcs\_provider\_username](#input\_vcs\_provider\_username) | The username for the VCS Provider. Required for 'bitbucket\_enterprise'. | `string` | `null` | no |
| <a name="input_vcs_provider_vcs_type"></a> [vcs\_provider\_vcs\_type](#input\_vcs\_provider\_vcs\_type) | The type of VCS Provider. Valid values are 'github', 'github\_enterprise', 'gitlab', 'gitlab\_enterprise', and 'bitbucket\_enterprise'. | `string` | `"github"` | no |
| <a name="input_workspace_agent_pool_id"></a> [workspace\_agent\_pool\_id](#input\_workspace\_agent\_pool\_id) | The Agent Pool ID to assign to the Workspace. Can be overridden per workspace in the YAML file. | `string` | `null` | no |
| <a name="input_workspace_auto_apply"></a> [workspace\_auto\_apply](#input\_workspace\_auto\_apply) | Whether to automatically apply runs when they are queued. Can be overridden per workspace in the YAML file. | `bool` | `false` | no |
| <a name="input_workspace_auto_queue_runs"></a> [workspace\_auto\_queue\_runs](#input\_workspace\_auto\_queue\_runs) | Whether to automatically queue runs when a workspace's configuration changes. Can be overridden per workspace in the YAML file. Valid values are 'skip\_first', 'always', 'never', and 'on\_create\_only'. | `string` | `"always"` | no |
| <a name="input_workspace_deletion_protection_enabled"></a> [workspace\_deletion\_protection\_enabled](#input\_workspace\_deletion\_protection\_enabled) | Whether to enable deletion protection for the workspace. Can be overridden per workspace in the YAML file. | `bool` | `true` | no |
| <a name="input_workspace_execution_mode"></a> [workspace\_execution\_mode](#input\_workspace\_execution\_mode) | The execution mode for the workspace. Can be overridden per workspace in the YAML file. Valid values are 'remote' and 'local'. | `string` | `"remote"` | no |
| <a name="input_workspace_force_latest_run"></a> [workspace\_force\_latest\_run](#input\_workspace\_force\_latest\_run) | Whether to force a new run to be created for the workspace. Can be overridden per workspace in the YAML file. | `bool` | `false` | no |
| <a name="input_workspace_iac_platform"></a> [workspace\_iac\_platform](#input\_workspace\_iac\_platform) | The Infrastructure as Code platform for the workspace. Valid values are 'terraform' or 'opentofu'. | `string` | `"opentofu"` | no |
| <a name="input_workspace_module_version_id"></a> [workspace\_module\_version\_id](#input\_workspace\_module\_version\_id) | The Module Version ID to use for the workspace. Can be overridden per workspace in the YAML file. Must be in the format 'modver-<RANDOM STRING>'. This cannot be set when using a vcs repository as the source for the workspace. | `string` | `null` | no |
| <a name="input_workspace_remote_backend"></a> [workspace\_remote\_backend](#input\_workspace\_remote\_backend) | Whether Scalr manages the remote backend configuration. Can be overridden per workspace in the YAML file. | `bool` | `true` | no |
| <a name="input_workspace_remote_state_consumers"></a> [workspace\_remote\_state\_consumers](#input\_workspace\_remote\_state\_consumers) | List of Workspace IDs that can read the remote state of this workspace. Can be overridden per workspace in the YAML file. | `list(string)` | `null` | no |
| <a name="input_workspace_run_operation_timeout"></a> [workspace\_run\_operation\_timeout](#input\_workspace\_run\_operation\_timeout) | The maximum time, in minutes, that a run operation (plan or apply) can take before it is automatically canceled. Can be overridden per workspace in the YAML file. | `number` | `60` | no |
| <a name="input_workspace_ssh_key_id"></a> [workspace\_ssh\_key\_id](#input\_workspace\_ssh\_key\_id) | The SSH Key ID to use for the workspace. Can be overridden per workspace in the YAML file. | `string` | `null` | no |
| <a name="input_workspace_tag_ids"></a> [workspace\_tag\_ids](#input\_workspace\_tag\_ids) | List of Tag IDs to assign to the workspace. Can be overridden per workspace in the YAML file. | `list(string)` | `null` | no |
| <a name="input_workspace_terraform_version"></a> [workspace\_terraform\_version](#input\_workspace\_terraform\_version) | The opentofu or terraform version to use for the workspace. Can be overridden per workspace in the YAML file. Must be in the format 'X.Y.Z'. | `string` | `null` | no |
| <a name="input_workspace_type"></a> [workspace\_type](#input\_workspace\_type) | The type of workspace. Valid values are 'production', 'staging', 'testing', 'development', and 'unmapped'. | `string` | `"production"` | no |
| <a name="input_workspace_var_files"></a> [workspace\_var\_files](#input\_workspace\_var\_files) | A list of paths which hold the '.tfvars' files for the workspace. Can be overridden per workspace in the YAML file. | `list(string)` | `[]` | no |
| <a name="input_workspace_working_directory"></a> [workspace\_working\_directory](#input\_workspace\_working\_directory) | The working directory as a relative path which opentofu or terraform will run for the workspace. Can be overridden per workspace in the YAML file. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_environment_ids"></a> [environment\_ids](#output\_environment\_ids) | Map of Environment names to their Scalr Environment IDs. |
| <a name="output_provider_configuration_azurerm_ids"></a> [provider\_configuration\_azurerm\_ids](#output\_provider\_configuration\_azurerm\_ids) | Map of AzureRM Provider Configuration names to their Scalr Provider Configuration IDs. |
| <a name="output_provider_configuration_custom_ids"></a> [provider\_configuration\_custom\_ids](#output\_provider\_configuration\_custom\_ids) | Map of custom Provider Configuration names to their Scalr Provider Configuration IDs. |
| <a name="output_provider_configuration_google_ids"></a> [provider\_configuration\_google\_ids](#output\_provider\_configuration\_google\_ids) | Map of Google Provider Configuration names to their Scalr Provider Configuration IDs. |
| <a name="output_provider_configuration_ids"></a> [provider\_configuration\_ids](#output\_provider\_configuration\_ids) | Map of AWS Provider Configuration names to their Scalr Provider Configuration IDs. |
| <a name="output_vcs_provider_ids"></a> [vcs\_provider\_ids](#output\_vcs\_provider\_ids) | Map of VCS Provider names to their Scalr VCS Provider IDs. |
| <a name="output_workspace_ids"></a> [workspace\_ids](#output\_workspace\_ids) | Map of Workspace composite keys ('<environment>.<workspace>') to their Scalr Workspace IDs. |
<!-- END_TF_DOCS -->

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasaurus)
- [Brad Engberg](https://github.com/bradms98)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/zachreborn/terraform-modules.svg?style=for-the-badge
[contributors-url]: https://github.com/zachreborn/terraform-modules/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/zachreborn/terraform-modules.svg?style=for-the-badge
[forks-url]: https://github.com/zachreborn/terraform-modules/network/members
[stars-shield]: https://img.shields.io/github/stars/zachreborn/terraform-modules.svg?style=for-the-badge
[stars-url]: https://github.com/zachreborn/terraform-modules/stargazers
[issues-shield]: https://img.shields.io/github/issues/zachreborn/terraform-modules.svg?style=for-the-badge
[issues-url]: https://github.com/zachreborn/terraform-modules/issues
[license-shield]: https://img.shields.io/github/license/zachreborn/terraform-modules.svg?style=for-the-badge
[license-url]: https://github.com/zachreborn/terraform-modules/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
[product-screenshot]: /images/screenshot.webp
[Terraform.io]: https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform
[Terraform-url]: https://terraform.io
