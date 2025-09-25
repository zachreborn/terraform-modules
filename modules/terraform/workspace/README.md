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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Terraform Workspace Module</h3>
  <p align="center">
    This module generates and manages a terraform cloud workspace
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
module "client_prod_security" {
  source           = "github.com/zachreborn/terraform-modules//modules/terraform/workspace"
  identifier        = "github-repo/client_prod_security"
  name              = "client_prod_security"
  oauth_token_id    = var.github_oauth_token_id
  organization      = var.organization
  permission_map    = var.workspace_permissions_mapping
  terraform_version = "~>1.4.0"
}

variable "org_workspace_permissions_mapping" {
  description = "Map of permissions to set with each terraform workspace."
  type        = map
  default     = {
      "all_admin"      = {"id" = "team-fjkdlsafjska2411", "access" = "admin"}
      "cloud_read"     = {"id" = "team-fndsabfak2010144", "access" = "read"}
      "cloud_write"    = {"id" = "team-fdjkslajflkn4591", "access" = "write"}
      "security_read"  = {"id" = "team-fdsahfkdsnalka40", "access" = "read"}
      "security_write" = {"id" = "team-fjdkslajfdsa0140", "access" = "write"}
  }
}
```

### Dyanmic Authentication with AWS Example

This example uses an OIDC Identity Provider in AWS, an IAM role, and STS Assume functions to generate dynamic authentication.

```
module "client_prod_security" {
  source                = "github.com/zachreborn/terraform-modules//modules/terraform/workspace"
  enable_dynamic_auth   = true
  dynamic_auth_role_arn = "arn:aws:iam::111111111111:role/terraform_cloud"
  identifier            = "github-repo/client_prod_security"
  name                  = "client_prod_security"
  oauth_token_id        = var.github_oauth_token_id
  organization          = var.organization
  permission_map        = var.workspace_permissions_mapping
  terraform_version     = "~>1.4.0"
}

variable "org_workspace_permissions_mapping" {
  description = "Map of permissions to set with each terraform workspace."
  type        = map
  default     = {
      "all_admin"      = {"id" = "team-fjkdlsafjska2411", "access" = "admin"}
      "cloud_read"     = {"id" = "team-fndsabfak2010144", "access" = "read"}
      "cloud_write"    = {"id" = "team-fdjkslajflkn4591", "access" = "write"}
      "security_read"  = {"id" = "team-fdsahfkdsnalka40", "access" = "read"}
      "security_write" = {"id" = "team-fjdkslajfdsa0140", "access" = "write"}
  }
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
| <a name="requirement_tfe"></a> [tfe](#requirement_tfe)                   | >=0.42.0 |

## Providers

| Name                                             | Version  |
| ------------------------------------------------ | -------- |
| <a name="provider_tfe"></a> [tfe](#provider_tfe) | >=0.42.0 |

## Modules

No modules.

## Resources

| Name                                                                                                                       | Type     |
| -------------------------------------------------------------------------------------------------------------------------- | -------- |
| [tfe_team_access.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/team_access)            | resource |
| [tfe_variable.tfc_aws_provider_auth](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable) | resource |
| [tfe_variable.tfc_aws_run_role_arn](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable)  | resource |
| [tfe_workspace.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace)                | resource |

## Inputs

| Name                                                                                                                     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Type           | Default     | Required |
| ------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ----------- | :------: |
| <a name="input_agent_pool_id"></a> [agent_pool_id](#input_agent_pool_id)                                                 | (Optional) The ID of an agent pool to assign to the workspace. Requires execution_mode to be set to agent. This value must not be provided if execution_mode is set to any other value or if operations is provided.                                                                                                                                                                                                                                                                                            | `string`       | `null`      |    no    |
| <a name="input_allow_destroy_plan"></a> [allow_destroy_plan](#input_allow_destroy_plan)                                  | (Optional) Whether destroy plans can be queued on the workspace.                                                                                                                                                                                                                                                                                                                                                                                                                                                | `bool`         | `false`     |    no    |
| <a name="input_assessments_enabled"></a> [assessments_enabled](#input_assessments_enabled)                               | (Optional) Whether to regularly run health assessments such as drift detection on the workspace. Defaults to true.                                                                                                                                                                                                                                                                                                                                                                                              | `bool`         | `true`      |    no    |
| <a name="input_auto_apply"></a> [auto_apply](#input_auto_apply)                                                          | (Optional) Whether to automatically apply changes when a Terraform plan is successful. Defaults to false.                                                                                                                                                                                                                                                                                                                                                                                                       | `bool`         | `false`     |    no    |
| <a name="input_branch"></a> [branch](#input_branch)                                                                      | (Optional) The repository branch that Terraform will execute from. This defaults to the repository's default branch (e.g. main).                                                                                                                                                                                                                                                                                                                                                                                | `string`       | `null`      |    no    |
| <a name="input_description"></a> [description](#input_description)                                                       | (Optional) A description for the workspace.                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `string`       | `null`      |    no    |
| <a name="input_dynamic_auth_role_arn"></a> [dynamic_auth_role_arn](#input_dynamic_auth_role_arn)                         | (Optional) The ARN of the IAM role to assume when generating dynamic authentication for this workspace. This is only required if enable_dynamic_credentials is true.                                                                                                                                                                                                                                                                                                                                            | `string`       | `null`      |    no    |
| <a name="input_enable_dynamic_auth"></a> [enable_dynamic_auth](#input_enable_dynamic_auth)                               | (Optional) Whether to enable dynamic authentication for this workspace. Defaults to false.                                                                                                                                                                                                                                                                                                                                                                                                                      | `bool`         | `false`     |    no    |
| <a name="input_execution_mode"></a> [execution_mode](#input_execution_mode)                                              | (Optional) Which execution mode to use. Using Terraform Cloud, valid values are remote, local or agent. Defaults to remote. Using Terraform Enterprise, only remote and local execution modes are valid. When set to local, the workspace will be used for state storage only. This value must not be provided if operations is provided.                                                                                                                                                                       | `string`       | `"remote"`  |    no    |
| <a name="input_file_triggers_enabled"></a> [file_triggers_enabled](#input_file_triggers_enabled)                         | (Optional) Whether to filter runs based on the changed files in a VCS push. Defaults to false. If enabled, the working directory and trigger prefixes describe a set of paths which must contain changes for a VCS push to trigger a run. If disabled, any push will trigger a run.                                                                                                                                                                                                                             | `bool`         | `false`     |    no    |
| <a name="input_global_remote_state"></a> [global_remote_state](#input_global_remote_state)                               | (Optional) Whether the workspace allows all workspaces in the organization to access its state data during runs. If false, then only specifically approved workspaces can access its state (remote_state_consumer_ids).                                                                                                                                                                                                                                                                                         | `bool`         | `false`     |    no    |
| <a name="input_identifier"></a> [identifier](#input_identifier)                                                          | (Required) A reference to your VCS repository in the format <organization>/<repository> where <organization> and <repository> refer to the organization and repository in your VCS provider. The format for Azure DevOps is //\_git/.                                                                                                                                                                                                                                                                           | `string`       | n/a         |   yes    |
| <a name="input_ingress_submodules"></a> [ingress_submodules](#input_ingress_submodules)                                  | (Optional) Whether submodules should be fetched when cloning the VCS repository. Defaults to false.                                                                                                                                                                                                                                                                                                                                                                                                             | `bool`         | `false`     |    no    |
| <a name="input_name"></a> [name](#input_name)                                                                            | (Required) Name of the workspace.                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | `string`       | n/a         |   yes    |
| <a name="input_oauth_token_id"></a> [oauth_token_id](#input_oauth_token_id)                                              | (Required) The VCS Connection (OAuth Connection + Token) to use. This ID can be obtained from a tfe_oauth_client resource.                                                                                                                                                                                                                                                                                                                                                                                      | `string`       | n/a         |   yes    |
| <a name="input_organization"></a> [organization](#input_organization)                                                    | (Required) Name of the organization.                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | `string`       | n/a         |   yes    |
| <a name="input_permission_map"></a> [permission_map](#input_permission_map)                                              | (Required) The permissions map which maps the team_id to the permission access level. Exampe: 'terraform_all_admin = {id = team-fdsa5122q6rwYXP, access = admin}'                                                                                                                                                                                                                                                                                                                                               | `map(any)`     | n/a         |   yes    |
| <a name="input_queue_all_runs"></a> [queue_all_runs](#input_queue_all_runs)                                              | (Optional) Whether the workspace should start automatically performing runs immediately after its creation. Defaults to true. When set to false, runs triggered by a webhook (such as a commit in VCS) will not be queued until at least one run has been manually queued. Note: This default differs from the Terraform Cloud API default, which is false. The provider uses true as any workspace provisioned with false would need to then have a run manually queued out-of-band before accepting webhooks. | `bool`         | `true`      |    no    |
| <a name="input_remote_state_consumer_ids"></a> [remote_state_consumer_ids](#input_remote_state_consumer_ids)             | (Optional) The set of workspace IDs set as explicit remote state consumers for the given workspace.                                                                                                                                                                                                                                                                                                                                                                                                             | `list(string)` | `null`      |    no    |
| <a name="input_speculative_enabled"></a> [speculative_enabled](#input_speculative_enabled)                               | (Optional) Whether this workspace allows speculative plans. Defaults to true. Setting this to false prevents Terraform Cloud or the Terraform Enterprise instance from running plans on pull requests, which can improve security if the VCS repository is public or includes untrusted contributors.                                                                                                                                                                                                           | `bool`         | `true`      |    no    |
| <a name="input_ssh_key_id"></a> [ssh_key_id](#input_ssh_key_id)                                                          | (Optional) The ID of an SSH key to assign to the workspace.                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `string`       | `null`      |    no    |
| <a name="input_structured_run_output_enabled"></a> [structured_run_output_enabled](#input_structured_run_output_enabled) | (Optional) Whether this workspace should show output from Terraform runs using the enhanced UI when available. Defaults to true. Setting this to false ensures that all runs in this workspace will display their output as text logs.                                                                                                                                                                                                                                                                          | `bool`         | `true`      |    no    |
| <a name="input_tag_names"></a> [tag_names](#input_tag_names)                                                             | (Optional) A list of tag names for this workspace. Note that tags must only contain letters, numbers or colons.                                                                                                                                                                                                                                                                                                                                                                                                 | `list(string)` | `null`      |    no    |
| <a name="input_terraform_version"></a> [terraform_version](#input_terraform_version)                                     | (Optional) The version of Terraform to use for this workspace. This can be either an exact version or a version constraint (like ~> 1.0.0); if you specify a constraint, the workspace will always use the newest release that meets that constraint. Defaults to the latest available version.                                                                                                                                                                                                                 | `string`       | `"~>1.4.0"` |    no    |
| <a name="input_trigger_prefixes"></a> [trigger_prefixes](#input_trigger_prefixes)                                        | (Optional) List of repository-root-relative paths which describe all locations to be tracked for changes.                                                                                                                                                                                                                                                                                                                                                                                                       | `list(string)` | `null`      |    no    |
| <a name="input_working_directory"></a> [working_directory](#input_working_directory)                                     | (Optional) A relative path that Terraform will execute within. Defaults to the root of your repository.                                                                                                                                                                                                                                                                                                                                                                                                         | `string`       | `null`      |    no    |

## Outputs

| Name                                      | Description |
| ----------------------------------------- | ----------- |
| <a name="output_id"></a> [id](#output_id) | n/a         |

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
