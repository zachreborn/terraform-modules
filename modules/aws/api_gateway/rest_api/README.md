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

<h3 align="center">API Gateway</h3>
  <p align="center">
    This module creates an AWS API Gateway for REST APIs and subsequent configuration.
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

### Basic HTTP API Gateway Example

This example creates a basic HTTP API Gateway.

```
module "example_api_gateway" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/api_gateway/rest_api"

  name          = "example-api"
  protocol_type = "HTTP"
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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_api_gateway_base_path_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |
| [aws_api_gateway_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_method.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_resource.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_api_gateway_vpc_link.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_vpc_link) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_key_source"></a> [api\_key\_source](#input\_api\_key\_source) | The source of the API key for metering requests. Valid values are 'HEADER' and 'AUTHORIZER'. | `string` | `"HEADER"` | no |
| <a name="input_binary_media_types"></a> [binary\_media\_types](#input\_binary\_media\_types) | A list of binary media types supported by the Rest API. | `list(string)` | `[]` | no |
| <a name="input_body"></a> [body](#input\_body) | The body of the API definition in JSON format. | `string` | `null` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ARN of the ACM certificate for the custom domain. Required for custom domain. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | A description of the API. | `string` | `null` | no |
| <a name="input_disable_execute_api_endpoint"></a> [disable\_execute\_api\_endpoint](#input\_disable\_execute\_api\_endpoint) | Specifies whether the execute API endpoint is disabled. Defaults to false. | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Custom domain name for the API Gateway. Required for mTLS. | `string` | `null` | no |
| <a name="input_enable_mtls"></a> [enable\_mtls](#input\_enable\_mtls) | Enable mTLS configuration for the API Gateway | `bool` | `true` | no |
| <a name="input_endpoint_configuration"></a> [endpoint\_configuration](#input\_endpoint\_configuration) | The endpoint configuration for the API. This is a complex object. | <pre>object({<br/>    types            = list(string)           # List of endpoint types. Valid values are 'EDGE', 'REGIONAL', and 'PRIVATE'.<br/>    vpc_endpoint_ids = optional(list(string)) # List of VPC endpoint IDs for private endpoints. Only supported if the type is 'PRIVATE'.<br/>  })</pre> | `null` | no |
| <a name="input_endpoint_configuration_types"></a> [endpoint\_configuration\_types](#input\_endpoint\_configuration\_types) | List of endpoint types for the custom domain. Valid values: EDGE, REGIONAL, PRIVATE | `list(string)` | <pre>[<br/>  "REGIONAL"<br/>]</pre> | no |
| <a name="input_fail_on_warnings"></a> [fail\_on\_warnings](#input\_fail\_on\_warnings) | Specifies whether to fail on warnings when creating the API. Defaults to false. | `bool` | `false` | no |
| <a name="input_integrations"></a> [integrations](#input\_integrations) | A map of integrations for the API. Each key is a combination of HTTP method and resource path, and the value is a map of integration settings. | <pre>map(object({<br/>    type                    = string<br/>    uri                     = string<br/>    resource                = string<br/>    method                  = string # The method key this integration belongs to<br/>    credentials             = optional(string)<br/>    http_method             = optional(string)<br/>    integration_http_method = optional(string)<br/>    request_parameters      = optional(map(string))<br/>    request_templates       = optional(map(string))<br/>    passthrough_behavior    = optional(string)<br/>    content_handling        = optional(string)<br/>    timeout_milliseconds    = optional(number)<br/>    cache_key_parameters    = optional(list(string))<br/>    cache_namespace         = optional(string)<br/>    connection_type         = optional(string)<br/>    connection_id           = optional(string)<br/>    vpc_link_key            = optional(string) # The VPC Link key from vpc_links variable when using VPC_LINK<br/>  }))</pre> | `{}` | no |
| <a name="input_method_responses"></a> [method\_responses](#input\_method\_responses) | A map of method responses for the API. Each key is a combination of HTTP method and resource path, and the value is a map of response settings. | <pre>map(object({<br/>    resource            = string # The resource key this method response belongs to<br/>    method              = string # The method key this response belongs to<br/>    status_code         = string<br/>    response_models     = optional(map(string))<br/>    response_parameters = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_methods"></a> [methods](#input\_methods) | A map of methods to create for the API. Each key is the HTTP method (e.g., 'GET', 'POST') and the value is a map of method settings. | <pre>map(object({<br/>    resource             = string # The resource key this method belongs to<br/>    authorization_scopes = optional(list(string))<br/>    authorization        = string<br/>    authorizer_id        = optional(string)<br/>    api_key_required     = optional(bool)<br/>    http_method          = string<br/>    operation_name       = optional(string)<br/>    request_models       = optional(map(string))<br/>    request_parameters   = optional(map(string))<br/>    request_validator_id = optional(string)<br/>    response_models      = optional(map(string))<br/>    response_parameters  = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_minimum_compression_size"></a> [minimum\_compression\_size](#input\_minimum\_compression\_size) | The minimum compression size in bytes. Must be an integer between -1 and 10485760. Set to -1 to disable compression. Defaults to -1 (compression disabled). | `number` | `-1` | no |
| <a name="input_mtls_config"></a> [mtls\_config](#input\_mtls\_config) | mTLS configuration for the custom domain. Required when enable\_mtls is true. | <pre>object({<br/>    truststore_uri     = string           # S3 URI to the truststore file (e.g., s3://bucket-name/path/to/truststore.pem)<br/>    truststore_version = optional(string) # Version of the truststore file (use S3 object version_id)<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the API. This is required. | `string` | n/a | yes |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | A map of API Gateway-specific parameters that can be used to configure the API. | `map(string)` | `{}` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | The resource policy for the API in JSON format. | `string` | `null` | no |
| <a name="input_put_rest_api_mode"></a> [put\_rest\_api\_mode](#input\_put\_rest\_api\_mode) | The mode for the PUT Rest API operation. Valid values are 'merge' and 'overwrite'. | `string` | `"overwrite"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | A map of resources to create under the API. Each key is the resource path and the value is a map of resource settings. | <pre>map(object({<br/>    path_part = string<br/>  }))</pre> | `{}` | no |
| <a name="input_security_policy"></a> [security\_policy](#input\_security\_policy) | Security policy for the custom domain. Valid values: TLS\_1\_0, TLS\_1\_2 | `string` | `"TLS_1_2"` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | (Required) Name of the stage | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the API. | `map(string)` | `{}` | no |
| <a name="input_vpc_links"></a> [vpc\_links](#input\_vpc\_links) | A map of VPC links for the API. Each key is the name of the VPC link and the value is a map of VPC link settings. | <pre>map(object({<br/>    description = string<br/>    target_arns = list(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | ID of the REST API |
| <a name="output_api_name"></a> [api\_name](#output\_api\_name) | Name of the REST API |
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | ARN of the ACM certificate |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | Domain name of the API Gateway (if configured) |
| <a name="output_domain_name_hosted_zone_id"></a> [domain\_name\_hosted\_zone\_id](#output\_domain\_name\_hosted\_zone\_id) | Hosted zone ID for the API Gateway custom domain |
| <a name="output_domain_name_target_domain_name"></a> [domain\_name\_target\_domain\_name](#output\_domain\_name\_target\_domain\_name) | Target domain name for the API Gateway custom domain |
| <a name="output_execution_arn"></a> [execution\_arn](#output\_execution\_arn) | Execution ARN of the REST API |
| <a name="output_methods"></a> [methods](#output\_methods) | API Gateway methods created |
| <a name="output_resources"></a> [resources](#output\_resources) | API Gateway resources created |
| <a name="output_root_resource_id"></a> [root\_resource\_id](#output\_root\_resource\_id) | Resource ID of the REST API root resource |
| <a name="output_stage_invoke_url"></a> [stage\_invoke\_url](#output\_stage\_invoke\_url) | Invoke URL for the API Gateway stage |
| <a name="output_stage_name"></a> [stage\_name](#output\_stage\_name) | Name of the API Gateway stage |
| <a name="output_truststore_s3_uri"></a> [truststore\_s3\_uri](#output\_truststore\_s3\_uri) | S3 URI of the truststore file used for mTLS (from configuration) |
| <a name="output_truststore_version_id"></a> [truststore\_version\_id](#output\_truststore\_version\_id) | Version ID of the truststore file used for mTLS (from configuration) |
| <a name="output_vpc_links"></a> [vpc\_links](#output\_vpc\_links) | VPC Links created by this module |
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
