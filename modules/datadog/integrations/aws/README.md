[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Datadog AWS Integration</h3>
  <p align="center">
    This module manages Datadog - Amazon Web Services account integrations. It covers the full integration schema: authentication (IAM role or access keys), region filtering, Lambda log forwarding, CloudWatch metrics collection, resource configuration, and X-Ray trace collection. Optionally creates Datadog-generated IAM external IDs.
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
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Prerequisites

**For IAM role-based authentication (recommended):**

- An IAM role in the AWS account that Datadog can assume. Use `modules/aws/iam/role` to provision it.
- The IAM role trust policy must reference the Datadog AWS account and the external ID. If using `create_external_id = true`, obtain the external ID from the `external_ids` output and add it to the trust policy after applying.
- The role must have the Datadog-required IAM policies attached (see [Datadog's AWS integration documentation](https://docs.datadoghq.com/integrations/amazon_web_services/)).

**For access key-based authentication:**

- An IAM user with programmatic access and the required Datadog permissions.
- The access key ID and secret access key for that IAM user.

## Usage

### Role-Based Auth with Datadog-Generated External ID

```hcl
# Step 1: Create the integration (this generates the external ID)
module "datadog_aws" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/aws"

  aws_accounts = {
    prod = {
      aws_account_id     = "123456789012"
      aws_partition      = "aws"
      create_external_id = true
      account_tags       = ["env:prod"]

      auth_config = {
        aws_auth_config_role = {
          role_name = "DatadogIntegrationRole"
        }
      }

      metrics_config = {
        automute_enabled          = true
        collect_cloudwatch_alarms = true
        collect_custom_metrics    = false
        namespace_filters = {
          exclude_only = ["AWS/SQS", "AWS/ElasticMapReduce", "AWS/Usage"]
        }
      }

      resources_config = {
        cloud_security_posture_management_collection = true
        extended_collection                          = true
      }
    }
  }
}

# Step 2: Use the external ID in the IAM role trust policy
module "datadog_iam_role" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/role"

  name = "DatadogIntegrationRole"
  # ... trust policy referencing module.datadog_aws.external_ids["prod"]
}
```

### Access Key-Based Auth

```hcl
module "datadog_aws_keys" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/aws"

  aws_accounts = {
    staging = {
      aws_account_id = "234567890123"
      aws_partition  = "aws"

      auth_config = {
        aws_auth_config_keys = {
          access_key_id     = "<YOUR_AWS_ACCESS_KEY_ID>"
          secret_access_key = "<YOUR_AWS_SECRET_ACCESS_KEY>"
        }
      }
    }
  }
}
```

### Multi-Account with Log Forwarding

```hcl
module "datadog_aws_multi" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/aws"

  aws_accounts = {
    prod_us_east = {
      aws_account_id = "123456789012"
      aws_partition  = "aws"
      account_tags   = ["env:prod", "region:us-east-1"]

      auth_config = {
        aws_auth_config_role = {
          role_name = "DatadogIntegrationRole"
        }
      }

      aws_regions = {
        include_only = ["us-east-1", "us-west-2"]
      }

      logs_config = {
        lambda_forwarder = {
          lambdas = ["arn:aws:lambda:us-east-1:123456789012:function:datadog-forwarder"]
          sources = ["s3", "cloudfront"]
          log_source_config = {
            tag_filters = [
              {
                source = "s3"
                tags   = ["env:prod", "team:backend"]
              }
            ]
          }
        }
      }

      traces_config = {
        xray_services = {
          include_all = true
        }
      }
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `required_version = ">= 1.3.0"` — uses `optional()` with defaults inside object types, which requires Terraform/OpenTofu 1.3.0+. The Datadog provider itself mandates >= 1.1.5.
- This module uses `datadog_integration_aws_account` (current) and NOT the deprecated `datadog_integration_aws` resource.
- **Authentication**: Provide exactly one of `auth_config.aws_auth_config_role` or `auth_config.aws_auth_config_keys`. IAM role-based auth is the secure recommended default.
- **External ID workflow**: Set `create_external_id = true` to have Datadog generate an external ID. The ID is available in `outputs.external_ids`. A new external ID **must be used within 48 hours** before it expires. After obtaining the ID, update the IAM role trust policy to include it.
- `aws_accounts` contains sensitive fields (`auth_config.aws_auth_config_keys.secret_access_key`). The variable is not marked `sensitive = true` (doing so would prevent `for_each` on the resource), so callers should pass these values via environment variables (`TF_VAR_aws_accounts`), Terraform Cloud/HCP sensitive variables, or a secrets manager integration rather than in plain-text `.tfvars` files. The `external_ids` output is marked `sensitive = true`.
- `aws_regions`: defaults to `include_all = true`. Set `include_only` to restrict collection to specific regions.
- `metrics_config.namespace_filters`: if empty, Datadog defaults to excluding `["AWS/SQS", "AWS/ElasticMapReduce", "AWS/Usage"]` to reduce CloudWatch API costs.
- `resources_config.cloud_security_posture_management_collection` requires `extended_collection = true`.
- `traces_config.xray_services`: configure X-Ray service collection. Set `include_all = true` or provide `include_only` with specific service names.

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_datadog"></a> [datadog](#requirement\_datadog) | >= 4.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_datadog"></a> [datadog](#provider\_datadog) | 4.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [datadog_integration_aws_account.keys](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_aws_account) | resource |
| [datadog_integration_aws_account.role](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_aws_account) | resource |
| [datadog_integration_aws_external_id.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_aws_external_id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_accounts"></a> [aws\_accounts](#input\_aws\_accounts) | Map of AWS account integrations keyed by a logical name. Each entry creates one Datadog - AWS account integration. Contains sensitive fields (secret\_access\_key). | <pre>map(object({<br/>    aws_account_id     = string<br/>    aws_partition      = string<br/>    account_tags       = optional(list(string), [])<br/>    create_external_id = optional(bool, false)<br/><br/>    auth_config = object({<br/>      aws_auth_config_role = optional(object({<br/>        role_name   = string<br/>        external_id = optional(string)<br/>      }))<br/>      aws_auth_config_keys = optional(object({<br/>        access_key_id     = string<br/>        secret_access_key = string<br/>      }))<br/>    })<br/><br/>    aws_regions = optional(object({<br/>      include_all  = optional(bool, true)<br/>      include_only = optional(list(string))<br/>    }), {})<br/><br/>    logs_config = optional(object({<br/>      lambda_forwarder = optional(object({<br/>        lambdas = optional(list(string), [])<br/>        sources = optional(list(string), [])<br/>        log_source_config = optional(object({<br/>          tag_filters = optional(list(object({<br/>            source = string<br/>            tags   = list(string)<br/>          })), [])<br/>        }))<br/>      }), {})<br/>    }), {})<br/><br/>    metrics_config = optional(object({<br/>      automute_enabled          = optional(bool, true)<br/>      collect_cloudwatch_alarms = optional(bool, false)<br/>      collect_custom_metrics    = optional(bool, false)<br/>      enabled                   = optional(bool, true)<br/>      namespace_filters = optional(object({<br/>        exclude_only = optional(list(string))<br/>        include_only = optional(list(string))<br/>      }), {})<br/>      tag_filters = optional(list(object({<br/>        namespace = string<br/>        tags      = optional(list(string), [])<br/>      })), [])<br/>    }), {})<br/><br/>    resources_config = optional(object({<br/>      cloud_security_posture_management_collection = optional(bool, false)<br/>      extended_collection                          = optional(bool, true)<br/>    }), {})<br/><br/>    traces_config = optional(object({<br/>      xray_services = optional(object({<br/>        include_all  = optional(bool)<br/>        include_only = optional(list(string))<br/>      }), {})<br/>    }), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_aws_account_ids"></a> [aws\_account\_ids](#output\_aws\_account\_ids) | Map of AWS account integration IDs keyed by logical name (covers both role-based and key-based auth accounts). |
| <a name="output_external_ids"></a> [external\_ids](#output\_external\_ids) | Map of Datadog-generated AWS IAM external IDs keyed by logical name. Only populated for accounts where create\_external\_id = true. Use these values in the IAM role trust policy. |
<!-- END_TF_DOCS -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Acknowledgments

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasaurus)
- [Brad Engberg](https://github.com/bradms98)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
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
