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

```
module "scalr" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr"
  scalr_config = file("${path.module}/scalr_config.yaml")
}

```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement_scalr)             | >= 3.0   |

## Providers

| Name                                                   | Version |
| ------------------------------------------------------ | ------- |
| <a name="provider_scalr"></a> [scalr](#provider_scalr) | >= 3.0  |

## Modules

No modules.

## Resources

| Name                             | Type        |
| -------------------------------- | ----------- |
| scalr_environment.this           | resource    |
| scalr_provider_configuration.aws | resource    |
| scalr_workspace.this             | resource    |
| scalr_current_account.account    | data source |

## Inputs

| Name                                                                                                                                                               | Description                                                                                                                                                                                                                       | Type           | Default         | Required |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | --------------- | :------: |
| <a name="input_aws_access_key"></a> [aws_access_key](#input_aws_access_key)                                                                                        | The AWS access key.                                                                                                                                                                                                               | `string`       | `null`          |    no    |
| <a name="input_aws_account_type"></a> [aws_account_type](#input_aws_account_type)                                                                                  | The type of AWS account. Valid values are 'regular', 'gov-cloud', and 'cn-cloud'.                                                                                                                                                 | `string`       | `"regular"`     |    no    |
| <a name="input_aws_audience"></a> [aws_audience](#input_aws_audience)                                                                                              | The audience for the AWS credentials. Required if credentials_type is set to 'oidc'.                                                                                                                                              | `string`       | `null`          |    no    |
| <a name="input_aws_credentials_type"></a> [aws_credentials_type](#input_aws_credentials_type)                                                                      | The type of AWS credentials. Valid values are 'access_keys', 'oidc', and 'role_delegation'.                                                                                                                                       | `string`       | `"oidc"`        |    no    |
| <a name="input_aws_environments"></a> [aws_environments](#input_aws_environments)                                                                                  | List of Scalr Environments which the provider will be shared to.                                                                                                                                                                  | `list(string)` | `null`          |    no    |
| <a name="input_aws_external_id"></a> [aws_external_id](#input_aws_external_id)                                                                                     | The external ID to use when assuming the role. Required if aws_credentials_type is set to 'role_delegation' and the role requires an external ID.                                                                                 | `string`       | `null`          |    no    |
| <a name="input_aws_owners"></a> [aws_owners](#input_aws_owners)                                                                                                    | List of Scalr User IDs who will own the Provider Configuration.                                                                                                                                                                   | `list(string)` | `null`          |    no    |
| <a name="input_aws_provider_name"></a> [aws_provider_name](#input_aws_provider_name)                                                                               | Name of the AWS Provider Configuration.                                                                                                                                                                                           | `string`       | `"aws"`         |    no    |
| <a name="input_aws_role_arn"></a> [aws_role_arn](#input_aws_role_arn)                                                                                              | The ARN of the role to assume. Required if aws_credentials_type is set to 'oidc' or 'role_delegation'.                                                                                                                            | `string`       | `null`          |    no    |
| <a name="input_aws_secret_key"></a> [aws_secret_key](#input_aws_secret_key)                                                                                        | The AWS secret key.                                                                                                                                                                                                               | `string`       | `null`          |    no    |
| <a name="input_aws_trusted_entity_type"></a> [aws_trusted_entity_type](#input_aws_trusted_entity_type)                                                             | The type of trusted entity for the role. Valid values are 'aws_account' and 'aws_service'.                                                                                                                                        | `string`       | `"aws_account"` |    no    |
| <a name="input_default_environment_ids"></a> [default_environment_ids](#input_default_environment_ids)                                                             | List of Environment IDs to set the default Provider Configurations in.                                                                                                                                                            | `list(string)` | `null`          |    no    |
| <a name="input_environment_default_provider_configurations"></a> [environment_default_provider_configurations](#input_environment_default_provider_configurations) | List of Provider Configuration IDs to set as the default in the Environment.                                                                                                                                                      | `list(string)` | `null`          |    no    |
| <a name="input_environment_default_workspace_agent_pool_id"></a> [environment_default_workspace_agent_pool_id](#input_environment_default_workspace_agent_pool_id) | The default Agent Pool ID to assign to Workspaces in the Environment.                                                                                                                                                             | `string`       | `null`          |    no    |
| <a name="input_environment_federated_environments"></a> [environment_federated_environments](#input_environment_federated_environments)                            | List of Environment IDs to federate with this Environment.                                                                                                                                                                        | `list(string)` | `null`          |    no    |
| <a name="input_environment_mask_sensitive_output"></a> [environment_mask_sensitive_output](#input_environment_mask_sensitive_output)                               | Whether to mask sensitive output values in the Environment.                                                                                                                                                                       | `bool`         | `true`          |    no    |
| <a name="input_environment_remote_backend"></a> [environment_remote_backend](#input_environment_remote_backend)                                                    | Whether Scalr manages the remote backend configuration for the Environment.                                                                                                                                                       | `bool`         | `true`          |    no    |
| <a name="input_environment_remote_backend_overridable"></a> [environment_remote_backend_overridable](#input_environment_remote_backend_overridable)                | Whether Workspaces in the Environment can override the remote backend configuration.                                                                                                                                              | `bool`         | `false`         |    no    |
| <a name="input_environment_storage_profile_id"></a> [environment_storage_profile_id](#input_environment_storage_profile_id)                                        | The Storage Profile ID to use for the Environment.                                                                                                                                                                                | `string`       | `null`          |    no    |
| <a name="input_environment_tag_ids"></a> [environment_tag_ids](#input_environment_tag_ids)                                                                         | List of Tag IDs to assign to the Environment.                                                                                                                                                                                     | `list(string)` | `null`          |    no    |
| <a name="input_environments_config"></a> [environments_config](#input_environments_config)                                                                         | YAML formatted file defining environments and their workspaces.                                                                                                                                                                   | `string`       | n/a             |   yes    |
| <a name="input_export_shell_variables"></a> [export_shell_variables](#input_export_shell_variables)                                                                | Whether to export provider credentials as shell variables when using the Scalr CLI.                                                                                                                                               | `bool`         | `false`         |    no    |
| <a name="input_workspace_agent_pool_id"></a> [workspace_agent_pool_id](#input_workspace_agent_pool_id)                                                             | The Agent Pool ID to assign to the Workspace. Can be overridden per workspace in the YAML file.                                                                                                                                   | `string`       | `null`          |    no    |
| <a name="input_workspace_auto_apply"></a> [workspace_auto_apply](#input_workspace_auto_apply)                                                                      | Whether to automatically apply runs when they are queued. Can be overridden per workspace in the YAML file.                                                                                                                       | `bool`         | `false`         |    no    |
| <a name="input_workspace_auto_queue_runs"></a> [workspace_auto_queue_runs](#input_workspace_auto_queue_runs)                                                       | Whether to automatically queue runs when a workspace's configuration changes. Can be overridden per workspace in the YAML file. Valid values are 'skip_first', 'always', 'never', and 'on_create_only'.                           | `string`       | `"always"`      |    no    |
| <a name="input_workspace_deletion_protection_enabled"></a> [workspace_deletion_protection_enabled](#input_workspace_deletion_protection_enabled)                   | Whether to enable deletion protection for the workspace. Can be overridden per workspace in the YAML file.                                                                                                                        | `bool`         | `true`          |    no    |
| <a name="input_workspace_execution_mode"></a> [workspace_execution_mode](#input_workspace_execution_mode)                                                          | The execution mode for the workspace. Can be overridden per workspace in the YAML file. Valid values are 'remote' and 'local'.                                                                                                    | `string`       | `"remote"`      |    no    |
| <a name="input_workspace_force_latest_run"></a> [workspace_force_latest_run](#input_workspace_force_latest_run)                                                    | Whether to force a new run to be created for the workspace. Can be overridden per workspace in the YAML file.                                                                                                                     | `bool`         | `false`         |    no    |
| <a name="input_workspace_iac_platform"></a> [workspace_iac_platform](#input_workspace_iac_platform)                                                                | The Infrastructure as Code platform for the workspace. Valid values are 'terraform' or 'opentofu'.                                                                                                                                | `string`       | `"opentofu"`    |    no    |
| <a name="input_workspace_module_version_id"></a> [workspace_module_version_id](#input_workspace_module_version_id)                                                 | The Module Version ID to use for the workspace. Can be overridden per workspace in the YAML file. Must be in the format 'modver-<RANDOM STRING>'. This cannot be set when using a vcs repository as the source for the workspace. | `string`       | `null`          |    no    |
| <a name="input_workspace_remote_backend"></a> [workspace_remote_backend](#input_workspace_remote_backend)                                                          | Whether Scalr manages the remote backend configuration. Can be overridden per workspace in the YAML file.                                                                                                                         | `bool`         | `true`          |    no    |
| <a name="input_workspace_remote_state_consumers"></a> [workspace_remote_state_consumers](#input_workspace_remote_state_consumers)                                  | List of Workspace IDs that can read the remote state of this workspace. Can be overridden per workspace in the YAML file.                                                                                                         | `list(string)` | `null`          |    no    |
| <a name="input_workspace_run_operation_timeout"></a> [workspace_run_operation_timeout](#input_workspace_run_operation_timeout)                                     | The maximum time, in minutes, that a run operation (plan or apply) can take before it is automatically canceled. Can be overridden per workspace in the YAML file.                                                                | `number`       | `60`            |    no    |
| <a name="input_workspace_ssh_key_id"></a> [workspace_ssh_key_id](#input_workspace_ssh_key_id)                                                                      | The SSH Key ID to use for the workspace. Can be overridden per workspace in the YAML file.                                                                                                                                        | `string`       | `null`          |    no    |
| <a name="input_workspace_tag_ids"></a> [workspace_tag_ids](#input_workspace_tag_ids)                                                                               | List of Tag IDs to assign to the workspace. Can be overridden per workspace in the YAML file.                                                                                                                                     | `list(string)` | `null`          |    no    |
| <a name="input_workspace_terraform_version"></a> [workspace_terraform_version](#input_workspace_terraform_version)                                                 | The opentofu or terraform version to use for the workspace. Can be overridden per workspace in the YAML file. Must be in the format 'X.Y.Z'.                                                                                      | `string`       | `null`          |    no    |
| <a name="input_workspace_type"></a> [workspace_type](#input_workspace_type)                                                                                        | The type of workspace. Valid values are 'production', 'staging', 'testing', 'development', and 'unmapped'.                                                                                                                        | `string`       | `"production"`  |    no    |
| <a name="input_workspace_var_files"></a> [workspace_var_files](#input_workspace_var_files)                                                                         | A list of paths which hold the '.tfvars' files for the workspace. Can be overridden per workspace in the YAML file.                                                                                                               | `list(string)` | `[]`            |    no    |
| <a name="input_workspace_working_directory"></a> [workspace_working_directory](#input_workspace_working_directory)                                                 | The working directory as a relative path which opentofu or terraform will run for the workspace. Can be overridden per workspace in the YAML file.                                                                                | `string`       | `null`          |    no    |

## Outputs

No outputs.

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

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)

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
