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

<h3 align="center">Amazon SageMaker User Profile</h3>
  <p align="center">
    Manages an Amazon SageMaker user profile within a SageMaker domain.
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
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#notes">Notes</a></li>
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

### IAM domain user profile

```hcl
module "sagemaker_user_profile" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/sagemaker/user_profile?ref=vX.X.X"

  domain_id         = module.sagemaker_domain.id
  user_profile_name = "data-scientist-jane"

  user_settings = {
    execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
  }

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
```

### SSO domain user profile with a custom instance type

```hcl
module "sagemaker_user_profile" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/sagemaker/user_profile?ref=vX.X.X"

  domain_id                      = module.sagemaker_domain.id
  user_profile_name              = "jane.doe"
  single_sign_on_user_identifier = "UserName"
  single_sign_on_user_value      = "jane.doe"

  user_settings = {
    execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"

    jupyter_lab_app_settings = {
      default_resource_spec = {
        instance_type = "ml.t3.medium"
      }
    }
  }

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- An AWS provider configured for the target account and region.
- An existing SageMaker domain, referenced by `domain_id`. Create it with `modules/aws/sagemaker/domain`.
- A SageMaker execution IAM role, supplied by ARN via `user_settings.execution_role`. Create it with `modules/aws/iam/role`. This module does not create IAM resources inline (`AGENTS.md` §2).
- For SSO domains, the associated IAM Identity Center username to supply as `single_sign_on_user_value`.

## Notes

- This module manages a single `aws_sagemaker_user_profile` per invocation, matching the single-instance convention used elsewhere in this library. Use `for_each` on the module block to manage many user profiles within a domain.
- The `user_settings` block is optional and mirrors the domain's `default_user_settings`, fully typed against the `aws >= 6.0.0` provider schema. When set it must include `execution_role`.
- SSO fields (`single_sign_on_user_identifier`, `single_sign_on_user_value`) are only valid when the parent domain's `auth_mode` is `SSO`. They must be null for `IAM` domains.
- No cross-cutting resources (IAM roles, KMS keys, security groups, EFS) are created inline; they are passed in by ARN/ID.
- No per-resource `region` argument is exposed; the module relies on the configured provider (matching the `athena/workgroup` precedent).

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_sagemaker_user_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_user_profile) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain_id"></a> [domain\_id](#input\_domain\_id) | (Required) The ID of the associated SageMaker domain. | `string` | n/a | yes |
| <a name="input_single_sign_on_user_identifier"></a> [single\_sign\_on\_user\_identifier](#input\_single\_sign\_on\_user\_identifier) | (Optional) A specifier for the type of value specified in single\_sign\_on\_user\_value. Only valid when the domain auth\_mode is SSO. The only supported value is UserName. If the domain auth\_mode is IAM, this field is disallowed. | `string` | `null` | no |
| <a name="input_single_sign_on_user_value"></a> [single\_sign\_on\_user\_value](#input\_single\_sign\_on\_user\_value) | (Optional) The username of the associated AWS Single Sign-On user for this user profile. Required when the domain auth\_mode is SSO, and must be null when the domain auth\_mode is IAM. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_user_profile_name"></a> [user\_profile\_name](#input\_user\_profile\_name) | (Required) The name for the user profile. | `string` | n/a | yes |
| <a name="input_user_settings"></a> [user\_settings](#input\_user\_settings) | (Optional) The user settings applied to the user profile. Must include execution\_role when set; all app-settings sub-blocks are optional and map directly to the aws\_sagemaker\_user\_profile user\_settings block. | <pre>object({<br/>    auto_mount_home_efs = optional(string)<br/>    default_landing_uri = optional(string)<br/>    execution_role      = string<br/>    security_groups     = optional(list(string))<br/>    studio_web_portal   = optional(string)<br/>    canvas_app_settings = optional(object({<br/>      direct_deploy_settings = optional(object({<br/>        status = optional(string)<br/>      }))<br/>      emr_serverless_settings = optional(object({<br/>        execution_role_arn = optional(string)<br/>        status             = optional(string)<br/>      }))<br/>      generative_ai_settings = optional(object({<br/>        amazon_bedrock_role_arn = optional(string)<br/>      }))<br/>      identity_provider_oauth_settings = optional(list(object({<br/>        data_source_name = optional(string)<br/>        secret_arn       = string<br/>        status           = optional(string)<br/>      })))<br/>      kendra_settings = optional(object({<br/>        status = optional(string)<br/>      }))<br/>      model_register_settings = optional(object({<br/>        cross_account_model_register_role_arn = optional(string)<br/>        status                                = optional(string)<br/>      }))<br/>      time_series_forecasting_settings = optional(object({<br/>        amazon_forecast_role_arn = optional(string)<br/>        status                   = optional(string)<br/>      }))<br/>      workspace_settings = optional(object({<br/>        s3_artifact_path = optional(string)<br/>        s3_kms_key_id    = optional(string)<br/>      }))<br/>    }))<br/>    code_editor_app_settings = optional(object({<br/>      built_in_lifecycle_config_arn = optional(string)<br/>      lifecycle_config_arns         = optional(list(string))<br/>      app_lifecycle_management = optional(object({<br/>        idle_settings = optional(object({<br/>          idle_timeout_in_minutes     = optional(number)<br/>          lifecycle_management        = optional(string)<br/>          max_idle_timeout_in_minutes = optional(number)<br/>          min_idle_timeout_in_minutes = optional(number)<br/>        }))<br/>      }))<br/>      custom_image = optional(list(object({<br/>        app_image_config_name = string<br/>        image_name            = string<br/>        image_version_number  = optional(number)<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>    custom_file_system_config = optional(list(object({<br/>      efs_file_system_config = optional(list(object({<br/>        file_system_id   = string<br/>        file_system_path = optional(string)<br/>      })))<br/>    })))<br/>    custom_posix_user_config = optional(object({<br/>      gid = number<br/>      uid = number<br/>    }))<br/>    jupyter_lab_app_settings = optional(object({<br/>      built_in_lifecycle_config_arn = optional(string)<br/>      lifecycle_config_arns         = optional(list(string))<br/>      app_lifecycle_management = optional(object({<br/>        idle_settings = optional(object({<br/>          idle_timeout_in_minutes     = optional(number)<br/>          lifecycle_management        = optional(string)<br/>          max_idle_timeout_in_minutes = optional(number)<br/>          min_idle_timeout_in_minutes = optional(number)<br/>        }))<br/>      }))<br/>      code_repository = optional(list(object({<br/>        repository_url = string<br/>      })))<br/>      custom_image = optional(list(object({<br/>        app_image_config_name = string<br/>        image_name            = string<br/>        image_version_number  = optional(number)<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>      emr_settings = optional(object({<br/>        assumable_role_arns = optional(list(string))<br/>        execution_role_arns = optional(list(string))<br/>      }))<br/>    }))<br/>    jupyter_server_app_settings = optional(object({<br/>      lifecycle_config_arns = optional(list(string))<br/>      code_repository = optional(list(object({<br/>        repository_url = string<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>    kernel_gateway_app_settings = optional(object({<br/>      lifecycle_config_arns = optional(list(string))<br/>      custom_image = optional(list(object({<br/>        app_image_config_name = string<br/>        image_name            = string<br/>        image_version_number  = optional(number)<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>    r_session_app_settings = optional(object({<br/>      custom_image = optional(list(object({<br/>        app_image_config_name = string<br/>        image_name            = string<br/>        image_version_number  = optional(number)<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>    r_studio_server_pro_app_settings = optional(object({<br/>      access_status = optional(string)<br/>      user_group    = optional(string)<br/>    }))<br/>    sharing_settings = optional(object({<br/>      notebook_output_option = optional(string)<br/>      s3_kms_key_id          = optional(string)<br/>      s3_output_path         = optional(string)<br/>    }))<br/>    space_storage_settings = optional(object({<br/>      default_ebs_storage_settings = optional(object({<br/>        default_ebs_volume_size_in_gb = number<br/>        maximum_ebs_volume_size_in_gb = number<br/>      }))<br/>    }))<br/>    studio_web_portal_settings = optional(object({<br/>      hidden_app_types      = optional(list(string))<br/>      hidden_instance_types = optional(list(string))<br/>      hidden_ml_tools       = optional(list(string))<br/>    }))<br/>    tensor_board_app_settings = optional(object({<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The user profile ARN. |
| <a name="output_home_efs_file_system_uid"></a> [home\_efs\_file\_system\_uid](#output\_home\_efs\_file\_system\_uid) | The ID of the user's profile in the Amazon Elastic File System (EFS) volume. |
| <a name="output_id"></a> [id](#output\_id) | The user profile Amazon Resource Name (ARN), which serves as its ID. |
| <a name="output_user_profile_name"></a> [user\_profile\_name](#output\_user\_profile\_name) | The name of the user profile. |
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
