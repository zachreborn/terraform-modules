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

<h3 align="center">AWS Glue Catalog Database</h3>
  <p align="center">
    Manages an AWS Glue Data Catalog database for data lakes and ML feature stores.
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

### Simple database

```hcl
module "analytics_database" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/glue/catalog_database?ref=vX.X.X"

  name        = "analytics"
  description = "Data lake database for the analytics team"

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
```

### Database with location and default table permissions

```hcl
module "feature_store_database" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/glue/catalog_database?ref=vX.X.X"

  name         = "feature_store"
  description  = "ML feature store backed by S3"
  location_uri = "s3://my-data-lake/feature_store/"

  parameters = {
    classification = "parquet"
  }

  create_table_default_permission = {
    permissions = ["ALL"]
    principal = {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
```

### Resource link to a database in another account/catalog

```hcl
module "shared_database_link" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/glue/catalog_database?ref=vX.X.X"

  name = "shared_link"

  target_database = {
    catalog_id    = "123456789012"
    database_name = "shared_source"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- An AWS provider configured for the target account and region.
- If using `catalog_id`, the ID of an existing Glue Data Catalog. When omitted the provider uses the current AWS account ID.
- If using `federated_database`, a pre-existing Glue connection referenced by `connection_name`.
- If using `target_database` for a resource link, an existing target catalog and database.

## Notes

- This module manages a single `aws_glue_catalog_database` per invocation, matching the single-instance convention used elsewhere in this library. Use `for_each` on the module block to manage many databases.
- No cross-cutting resources (IAM, KMS, S3 buckets, Lake Formation permissions) are created inline; those dependencies are supplied by the caller by ID/ARN.
- The `create_table_default_permission`, `federated_database`, and `target_database` blocks are optional and only emitted when their corresponding variable is non-null.
- No per-resource `region` argument is exposed on the database itself; the module relies on the configured provider. The nested `target_database.region` argument is a provider attribute of the resource-link target and is passed through.

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
| [aws_glue_catalog_database.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_catalog_id"></a> [catalog\_id](#input\_catalog\_id) | (Optional) ID of the Glue Catalog to create the database in. If omitted, this defaults to the AWS Account ID. | `string` | `null` | no |
| <a name="input_create_table_default_permission"></a> [create\_table\_default\_permission](#input\_create\_table\_default\_permission) | (Optional) Creates a set of default permissions on the table for principals. Provide the permissions list (for example, ["ALL"]) and the Lake Formation principal identifier. | <pre>object({<br/>    permissions = optional(list(string))<br/>    principal = optional(object({<br/>      data_lake_principal_identifier = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | (Optional) Description of the database. | `string` | `null` | no |
| <a name="input_federated_database"></a> [federated\_database](#input\_federated\_database) | (Optional) Configuration block that references an entity outside the AWS Glue Data Catalog. Provide the connection\_name of the Glue connection and the identifier of the federated database. | <pre>object({<br/>    connection_name = optional(string)<br/>    identifier      = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_location_uri"></a> [location\_uri](#input\_location\_uri) | (Optional) Location of the database (for example, an HDFS or S3 path). | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) Name of the Glue catalog database. Must contain only lowercase letters, numbers, and underscores. | `string` | n/a | yes |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | (Optional) Map of key-value pairs that define parameters and properties of the database. | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_target_database"></a> [target\_database](#input\_target\_database) | (Optional) Configuration block for a target database for resource linking. Provide the catalog\_id and database\_name of the target, and optionally the region of the target database. | <pre>object({<br/>    catalog_id    = string<br/>    database_name = string<br/>    region        = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the Glue catalog database. |
| <a name="output_catalog_id"></a> [catalog\_id](#output\_catalog\_id) | ID of the Glue Catalog the database lives in. |
| <a name="output_id"></a> [id](#output\_id) | Catalog ID and name of the database in the format catalog\_id:name. |
| <a name="output_name"></a> [name](#output\_name) | Name of the Glue catalog database. |
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
