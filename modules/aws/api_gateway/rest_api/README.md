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
| [aws_api_gateway_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_method.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_resource.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_vpc_link.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_vpc_link) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_key_source"></a> [api\_key\_source](#input\_api\_key\_source) | The source of the API key for metering requests. Valid values are 'HEADER' and 'AUTHORIZER'. | `string` | `"HEADER"` | no |
| <a name="input_binary_media_types"></a> [binary\_media\_types](#input\_binary\_media\_types) | A list of binary media types supported by the Rest API. | `list(string)` | `[]` | no |
| <a name="input_body"></a> [body](#input\_body) | The body of the API definition in JSON format. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | A description of the API. | `string` | `null` | no |
| <a name="input_disable_execute_api_endpoint"></a> [disable\_execute\_api\_endpoint](#input\_disable\_execute\_api\_endpoint) | Specifies whether the execute API endpoint is disabled. Defaults to false. | `bool` | `false` | no |
| <a name="input_endpoint_configuration"></a> [endpoint\_configuration](#input\_endpoint\_configuration) | The endpoint configuration for the API. This is a complex object. | <pre>object({<br/>    types            = list(string)           # List of endpoint types. Valid values are 'EDGE', 'REGIONAL', and 'PRIVATE'.<br/>    vpc_endpoint_ids = optional(list(string)) # List of VPC endpoint IDs for private endpoints. Only supported if the type is 'PRIVATE'.<br/>  })</pre> | `null` | no |
| <a name="input_fail_on_warnings"></a> [fail\_on\_warnings](#input\_fail\_on\_warnings) | Specifies whether to fail on warnings when creating the API. Defaults to false. | `bool` | `false` | no |
| <a name="input_integrations"></a> [integrations](#input\_integrations) | A map of integrations for the API. Each key is a combination of HTTP method and resource path, and the value is a map of integration settings. | <pre>map(object({<br/>    type                 = string<br/>    uri                  = string<br/>    http_method          = optional(string)<br/>    request_parameters   = optional(map(string))<br/>    request_templates    = optional(map(string))<br/>    passthrough_behavior = optional(string)<br/>    content_handling     = optional(string)<br/>    timeout_milliseconds = optional(number)<br/>    cache_key_parameters = optional(list(string))<br/>    cache_namespace      = optional(string)<br/>    connection_type      = optional(string)<br/>    connection_id        = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_method_responses"></a> [method\_responses](#input\_method\_responses) | A map of method responses for the API. Each key is a combination of HTTP method and resource path, and the value is a map of response settings. | <pre>map(object({<br/>    status_code         = string<br/>    response_models     = optional(map(string))<br/>    response_parameters = optional(map(string))<br/>    resource            = string<br/>  }))</pre> | `{}` | no |
| <a name="input_methods"></a> [methods](#input\_methods) | A map of methods to create for the API. Each key is the HTTP method (e.g., 'GET', 'POST') and the value is a map of method settings. | <pre>map(object({<br/>    authorization_scopes = optional(list(string)) #NOTE: Zach<br/>    authorization_type   = string<br/>    authorizer_id        = optional(string)<br/>    api_key_required     = optional(bool)<br/>    method               = optional(string) #NOTE: Zach<br/>    operation_name       = optional(string) #NOTE: Zach<br/>    resource             = optional(string) #NOTE: Zach<br/>    request_models       = optional(map(string))<br/>    request_parameters   = optional(map(string))<br/>    request_validator_id = optional(string) #NOTE: Zach<br/>    response_models      = optional(map(string))<br/>    response_parameters  = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_minimum_compression_size"></a> [minimum\_compression\_size](#input\_minimum\_compression\_size) | The minimum compression size in bytes. Must be either a string containing an integer between -1 and 10485760 or set to null. Defaults to null, which disables compression. | `number` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the API. This is required. | `string` | n/a | yes |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | A map of API Gateway-specific parameters that can be used to configure the API. | `map(string)` | `{}` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | The resource policy for the API in JSON format. | `string` | `null` | no |
| <a name="input_put_rest_api_mode"></a> [put\_rest\_api\_mode](#input\_put\_rest\_api\_mode) | The mode for the PUT Rest API operation. Valid values are 'merge' and 'overwrite'. | `string` | `"overwrite"` | no |
| <a name="input_resource_paths"></a> [resource\_paths](#input\_resource\_paths) | A list of resource paths to create under the API. Each path is a string. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the API. | `map(string)` | `{}` | no |
| <a name="input_vpc_links"></a> [vpc\_links](#input\_vpc\_links) | A map of VPC links for the API. Each key is the name of the VPC link and the value is a map of VPC link settings. | <pre>map(object({<br/>    description = string<br/>    target_arns = list(string)<br/>  }))</pre> | `{}` | no |

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
