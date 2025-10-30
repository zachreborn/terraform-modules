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

<h3 align="center">module_name</h3>
  <p align="center">
    module_description
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
module test {
  source = 

  variable = 
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| scalr_environment.this | resource |
| scalr_provider_configuration.aws | resource |
| scalr_workspace.this | resource |
| scalr_current_account.account | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | The AWS access key. | `string` | `null` | no |
| <a name="input_aws_account_type"></a> [aws\_account\_type](#input\_aws\_account\_type) | The type of AWS account. Valid values are 'regular', 'gov-cloud', and 'cn-cloud'. | `string` | `"regular"` | no |
| <a name="input_aws_audience"></a> [aws\_audience](#input\_aws\_audience) | The audience for the AWS credentials. Required if credentials\_type is set to 'oidc'. | `string` | `null` | no |
| <a name="input_aws_credentials_type"></a> [aws\_credentials\_type](#input\_aws\_credentials\_type) | The type of AWS credentials. Valid values are 'access\_keys', 'oidc', and 'role\_delegation'. | `string` | `"oidc"` | no |
| <a name="input_aws_environments"></a> [aws\_environments](#input\_aws\_environments) | List of Scalr Environments which the provider will be shared to. | `list(string)` | `null` | no |
| <a name="input_aws_external_id"></a> [aws\_external\_id](#input\_aws\_external\_id) | The external ID to use when assuming the role. Required if aws\_credentials\_type is set to 'role\_delegation' and the role requires an external ID. | `string` | `null` | no |
| <a name="input_aws_owners"></a> [aws\_owners](#input\_aws\_owners) | List of Scalr User IDs who will own the Provider Configuration. | `list(string)` | `null` | no |
| <a name="input_aws_provider_name"></a> [aws\_provider\_name](#input\_aws\_provider\_name) | Name of the AWS Provider Configuration. | `string` | `"aws"` | no |
| <a name="input_aws_role_arn"></a> [aws\_role\_arn](#input\_aws\_role\_arn) | The ARN of the role to assume. Required if aws\_credentials\_type is set to 'oidc' or 'role\_delegation'. | `string` | `null` | no |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | The AWS secret key. | `string` | `null` | no |
| <a name="input_aws_trusted_entity_type"></a> [aws\_trusted\_entity\_type](#input\_aws\_trusted\_entity\_type) | The type of trusted entity for the role. Valid values are 'aws\_account' and 'aws\_service'. | `string` | `"aws_account"` | no |
| <a name="input_default_environment_ids"></a> [default\_environment\_ids](#input\_default\_environment\_ids) | List of Environment IDs to set the default Provider Configurations in. | `list(string)` | `null` | no |
| <a name="input_environment_default_provider_configurations"></a> [environment\_default\_provider\_configurations](#input\_environment\_default\_provider\_configurations) | List of Provider Configuration IDs to set as the default in the Environment. | `list(string)` | `null` | no |
| <a name="input_environment_default_workspace_agent_pool_id"></a> [environment\_default\_workspace\_agent\_pool\_id](#input\_environment\_default\_workspace\_agent\_pool\_id) | The default Agent Pool ID to assign to Workspaces in the Environment. | `string` | `null` | no |
| <a name="input_environment_federated_environments"></a> [environment\_federated\_environments](#input\_environment\_federated\_environments) | List of Environment IDs to federate with this Environment. | `list(string)` | `null` | no |
| <a name="input_environment_mask_sensitive_output"></a> [environment\_mask\_sensitive\_output](#input\_environment\_mask\_sensitive\_output) | Whether to mask sensitive output values in the Environment. | `bool` | `true` | no |
| <a name="input_environment_remote_backend"></a> [environment\_remote\_backend](#input\_environment\_remote\_backend) | Whether Scalr manages the remote backend configuration for the Environment. | `bool` | `true` | no |
| <a name="input_environment_remote_backend_overridable"></a> [environment\_remote\_backend\_overridable](#input\_environment\_remote\_backend\_overridable) | Whether Workspaces in the Environment can override the remote backend configuration. | `bool` | `false` | no |
| <a name="input_environment_storage_profile_id"></a> [environment\_storage\_profile\_id](#input\_environment\_storage\_profile\_id) | The Storage Profile ID to use for the Environment. | `string` | `null` | no |
| <a name="input_environment_tag_ids"></a> [environment\_tag\_ids](#input\_environment\_tag\_ids) | List of Tag IDs to assign to the Environment. | `list(string)` | `null` | no |
| <a name="input_environments_config"></a> [environments\_config](#input\_environments\_config) | YAML formatted file defining environments and their workspaces. | `string` | n/a | yes |
| <a name="input_export_shell_variables"></a> [export\_shell\_variables](#input\_export\_shell\_variables) | Whether to export provider credentials as shell variables when using the Scalr CLI. | `bool` | `false` | no |
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

* [Zachary Hill](https://zacharyhill.co)
* [Jake Jones](https://github.com/jakeasarus)

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