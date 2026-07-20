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

<h3 align="center">Amazon SageMaker Domain</h3>
  <p align="center">
    Manages an Amazon SageMaker Studio domain with VPC integration.
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

### VpcOnly IAM domain

```hcl
module "sagemaker_domain" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/sagemaker/domain?ref=vX.X.X"

  domain_name = "ml-platform"
  auth_mode   = "IAM"
  vpc_id      = "vpc-0123456789abcdef0"
  subnet_ids  = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  kms_key_id  = "arn:aws:kms:us-east-1:123456789012:key/abc123"

  default_user_settings = {
    execution_role  = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    security_groups = ["sg-0123456789abcdef0"]
  }

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
```

### Domain with JupyterLab default resource spec and space defaults

```hcl
module "sagemaker_domain" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/sagemaker/domain?ref=vX.X.X"

  domain_name             = "data-science"
  auth_mode               = "IAM"
  vpc_id                  = "vpc-0123456789abcdef0"
  subnet_ids              = ["subnet-0123456789abcdef0"]
  app_network_access_type = "VpcOnly"

  default_user_settings = {
    execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"

    jupyter_lab_app_settings = {
      default_resource_spec = {
        instance_type = "ml.t3.medium"
      }
    }
  }

  default_space_settings = {
    execution_role = "arn:aws:iam::123456789012:role/sagemaker-space-role"
  }

  retention_policy = {
    home_efs_file_system = "Retain"
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
- A pre-provisioned VPC (`vpc_id`) and one or more subnets (`subnet_ids`). Create these with `modules/aws/vpc` or an equivalent.
- A SageMaker execution IAM role, supplied by ARN via `default_user_settings.execution_role`. Create it with `modules/aws/iam/role`. This module does not create IAM resources inline (`AGENTS.md` §2).
- (Optional) A KMS customer managed key (`kms_key_id`) for encrypting the domain EFS volume. Create it with `modules/aws/kms`.
- (Optional) Security groups supplied by ID for the user settings and/or domain boundary. Create them with `modules/aws/security_group`.

## Notes

- This module manages a single `aws_sagemaker_domain`. A SageMaker domain is one-per-account/region (similar to a VPC), so no map/`for_each` input is provided.
- **Secure-by-default:** `app_network_access_type` defaults to `VpcOnly` (the provider default is `PublicInternetOnly`). `VpcOnly` requires the caller to supply routable subnets and the necessary VPC endpoints/NAT for SageMaker traffic. Override to `PublicInternetOnly` if that posture is required.
- Encryption of the domain EFS volume is caller-controlled via `kms_key_id`. When null, an AWS managed key is used.
- `default_user_settings` is required and must include `execution_role`. All nested app-settings blocks are optional and mirror the `aws >= 6.0.0` provider schema exactly.
- No cross-cutting resources (IAM roles, KMS keys, security groups, VPC/subnets, EFS) are created inline; they are passed in by ARN/ID.
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
| [aws_sagemaker_domain.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_domain) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_network_access_type"></a> [app\_network\_access\_type](#input\_app\_network\_access\_type) | (Optional) Specifies the VPC used for non-EFS traffic. Valid values are PublicInternetOnly and VpcOnly. Defaults to VpcOnly for a secure-by-default posture (the provider default is PublicInternetOnly). | `string` | `"VpcOnly"` | no |
| <a name="input_app_security_group_management"></a> [app\_security\_group\_management](#input\_app\_security\_group\_management) | (Optional) The entity that creates and manages the required security groups for inter-app communication in VPCOnly mode. Valid values are Service and Customer. | `string` | `null` | no |
| <a name="input_auth_mode"></a> [auth\_mode](#input\_auth\_mode) | (Required) The mode of authentication that members use to access the domain. Valid values are IAM and SSO. | `string` | n/a | yes |
| <a name="input_default_space_settings"></a> [default\_space\_settings](#input\_default\_space\_settings) | (Optional) The default settings for shared spaces created in the domain. Must include execution\_role when set. | <pre>object({<br/>    execution_role  = string<br/>    security_groups = optional(list(string))<br/>    custom_file_system_config = optional(list(object({<br/>      efs_file_system_config = optional(object({<br/>        file_system_id   = string<br/>        file_system_path = string<br/>      }))<br/>    })))<br/>    custom_posix_user_config = optional(object({<br/>      gid = number<br/>      uid = number<br/>    }))<br/>    jupyter_lab_app_settings = optional(object({<br/>      built_in_lifecycle_config_arn = optional(string)<br/>      lifecycle_config_arns         = optional(list(string))<br/>      app_lifecycle_management = optional(object({<br/>        idle_settings = optional(object({<br/>          idle_timeout_in_minutes     = optional(number)<br/>          lifecycle_management        = optional(string)<br/>          max_idle_timeout_in_minutes = optional(number)<br/>          min_idle_timeout_in_minutes = optional(number)<br/>        }))<br/>      }))<br/>      code_repository = optional(list(object({<br/>        repository_url = string<br/>      })))<br/>      custom_image = optional(list(object({<br/>        app_image_config_name = string<br/>        image_name            = string<br/>        image_version_number  = optional(number)<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>      emr_settings = optional(object({<br/>        assumable_role_arns = optional(list(string))<br/>        execution_role_arns = optional(list(string))<br/>      }))<br/>    }))<br/>    jupyter_server_app_settings = optional(object({<br/>      lifecycle_config_arns = optional(list(string))<br/>      code_repository = optional(list(object({<br/>        repository_url = string<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>    kernel_gateway_app_settings = optional(object({<br/>      lifecycle_config_arns = optional(list(string))<br/>      custom_image = optional(list(object({<br/>        app_image_config_name = string<br/>        image_name            = string<br/>        image_version_number  = optional(number)<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>    space_storage_settings = optional(object({<br/>      default_ebs_storage_settings = optional(object({<br/>        default_ebs_volume_size_in_gb = number<br/>        maximum_ebs_volume_size_in_gb = number<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_default_user_settings"></a> [default\_user\_settings](#input\_default\_user\_settings) | (Required) The default user settings applied to the domain. Must include execution\_role; all app-settings sub-blocks are optional and map directly to the aws\_sagemaker\_domain default\_user\_settings block. | <pre>object({<br/>    auto_mount_home_efs = optional(string)<br/>    default_landing_uri = optional(string)<br/>    execution_role      = string<br/>    security_groups     = optional(list(string))<br/>    studio_web_portal   = optional(string)<br/>    canvas_app_settings = optional(object({<br/>      direct_deploy_settings = optional(object({<br/>        status = optional(string)<br/>      }))<br/>      emr_serverless_settings = optional(object({<br/>        execution_role_arn = optional(string)<br/>        status             = optional(string)<br/>      }))<br/>      generative_ai_settings = optional(object({<br/>        amazon_bedrock_role_arn = optional(string)<br/>      }))<br/>      identity_provider_oauth_settings = optional(list(object({<br/>        data_source_name = optional(string)<br/>        secret_arn       = string<br/>        status           = optional(string)<br/>      })))<br/>      kendra_settings = optional(object({<br/>        status = optional(string)<br/>      }))<br/>      model_register_settings = optional(object({<br/>        cross_account_model_register_role_arn = optional(string)<br/>        status                                = optional(string)<br/>      }))<br/>      time_series_forecasting_settings = optional(object({<br/>        amazon_forecast_role_arn = optional(string)<br/>        status                   = optional(string)<br/>      }))<br/>      workspace_settings = optional(object({<br/>        s3_artifact_path = optional(string)<br/>        s3_kms_key_id    = optional(string)<br/>      }))<br/>    }))<br/>    code_editor_app_settings = optional(object({<br/>      built_in_lifecycle_config_arn = optional(string)<br/>      lifecycle_config_arns         = optional(list(string))<br/>      app_lifecycle_management = optional(object({<br/>        idle_settings = optional(object({<br/>          idle_timeout_in_minutes     = optional(number)<br/>          lifecycle_management        = optional(string)<br/>          max_idle_timeout_in_minutes = optional(number)<br/>          min_idle_timeout_in_minutes = optional(number)<br/>        }))<br/>      }))<br/>      custom_image = optional(list(object({<br/>        app_image_config_name = string<br/>        image_name            = string<br/>        image_version_number  = optional(number)<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>    custom_file_system_config = optional(list(object({<br/>      efs_file_system_config = optional(object({<br/>        file_system_id   = string<br/>        file_system_path = string<br/>      }))<br/>    })))<br/>    custom_posix_user_config = optional(object({<br/>      gid = number<br/>      uid = number<br/>    }))<br/>    jupyter_lab_app_settings = optional(object({<br/>      built_in_lifecycle_config_arn = optional(string)<br/>      lifecycle_config_arns         = optional(list(string))<br/>      app_lifecycle_management = optional(object({<br/>        idle_settings = optional(object({<br/>          idle_timeout_in_minutes     = optional(number)<br/>          lifecycle_management        = optional(string)<br/>          max_idle_timeout_in_minutes = optional(number)<br/>          min_idle_timeout_in_minutes = optional(number)<br/>        }))<br/>      }))<br/>      code_repository = optional(list(object({<br/>        repository_url = string<br/>      })))<br/>      custom_image = optional(list(object({<br/>        app_image_config_name = string<br/>        image_name            = string<br/>        image_version_number  = optional(number)<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>      emr_settings = optional(object({<br/>        assumable_role_arns = optional(list(string))<br/>        execution_role_arns = optional(list(string))<br/>      }))<br/>    }))<br/>    jupyter_server_app_settings = optional(object({<br/>      lifecycle_config_arns = optional(list(string))<br/>      code_repository = optional(list(object({<br/>        repository_url = string<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>    kernel_gateway_app_settings = optional(object({<br/>      lifecycle_config_arns = optional(list(string))<br/>      custom_image = optional(list(object({<br/>        app_image_config_name = string<br/>        image_name            = string<br/>        image_version_number  = optional(number)<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>    r_session_app_settings = optional(object({<br/>      custom_image = optional(list(object({<br/>        app_image_config_name = string<br/>        image_name            = string<br/>        image_version_number  = optional(number)<br/>      })))<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>    r_studio_server_pro_app_settings = optional(object({<br/>      access_status = optional(string)<br/>      user_group    = optional(string)<br/>    }))<br/>    sharing_settings = optional(object({<br/>      notebook_output_option = optional(string)<br/>      s3_kms_key_id          = optional(string)<br/>      s3_output_path         = optional(string)<br/>    }))<br/>    space_storage_settings = optional(object({<br/>      default_ebs_storage_settings = optional(object({<br/>        default_ebs_volume_size_in_gb = number<br/>        maximum_ebs_volume_size_in_gb = number<br/>      }))<br/>    }))<br/>    studio_web_portal_settings = optional(object({<br/>      hidden_app_types      = optional(list(string))<br/>      hidden_instance_types = optional(list(string))<br/>      hidden_ml_tools       = optional(list(string))<br/>    }))<br/>    tensor_board_app_settings = optional(object({<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>  })</pre> | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | (Required) The domain name. | `string` | n/a | yes |
| <a name="input_domain_settings"></a> [domain\_settings](#input\_domain\_settings) | (Optional) Domain-level settings such as the execution role identity config, domain-boundary security groups, Docker access, and RStudio server settings. | <pre>object({<br/>    execution_role_identity_config = optional(string)<br/>    security_group_ids             = optional(list(string))<br/>    docker_settings = optional(object({<br/>      enable_docker_access      = optional(string)<br/>      vpc_only_trusted_accounts = optional(list(string))<br/>    }))<br/>    r_studio_server_pro_domain_settings = optional(object({<br/>      domain_execution_role_arn    = string<br/>      r_studio_connect_url         = optional(string)<br/>      r_studio_package_manager_url = optional(string)<br/>      default_resource_spec = optional(object({<br/>        instance_type                 = optional(string)<br/>        lifecycle_config_arn          = optional(string)<br/>        sagemaker_image_arn           = optional(string)<br/>        sagemaker_image_version_alias = optional(string)<br/>        sagemaker_image_version_arn   = optional(string)<br/>      }))<br/>    }))<br/>    trusted_identity_propagation_settings = optional(object({<br/>      status = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | (Optional) The AWS KMS customer managed key (CMK) used to encrypt the EFS volume attached to the domain. If null, an AWS managed key is used. | `string` | `null` | no |
| <a name="input_retention_policy"></a> [retention\_policy](#input\_retention\_policy) | (Optional) The retention policy for data stored on the domain EFS volume. Set home\_efs\_file\_system to Retain or Delete. | <pre>object({<br/>    home_efs_file_system = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | (Required) The VPC subnets that the domain uses for communication. | `list(string)` | n/a | yes |
| <a name="input_tag_propagation"></a> [tag\_propagation](#input\_tag\_propagation) | (Optional) Indicates whether custom tag propagation is supported for the domain. Valid values are ENABLED and DISABLED. Defaults to DISABLED. | `string` | `"DISABLED"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | (Required) The ID of the Amazon Virtual Private Cloud (VPC) that the domain uses for communication. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the SageMaker domain. |
| <a name="output_home_efs_file_system_id"></a> [home\_efs\_file\_system\_id](#output\_home\_efs\_file\_system\_id) | The ID of the Amazon Elastic File System (EFS) managed by this domain. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the SageMaker domain. |
| <a name="output_security_group_id_for_domain_boundary"></a> [security\_group\_id\_for\_domain\_boundary](#output\_security\_group\_id\_for\_domain\_boundary) | The ID of the security group that authorizes traffic between the RSessionGateway apps and the RStudioServerPro app. |
| <a name="output_single_sign_on_application_arn"></a> [single\_sign\_on\_application\_arn](#output\_single\_sign\_on\_application\_arn) | The ARN of the application managed by SageMaker in IAM Identity Center. |
| <a name="output_single_sign_on_managed_application_instance_id"></a> [single\_sign\_on\_managed\_application\_instance\_id](#output\_single\_sign\_on\_managed\_application\_instance\_id) | The SSO managed application instance ID. |
| <a name="output_url"></a> [url](#output\_url) | The domain's URL used to access the SageMaker Studio environment. |
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
