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
    This module creates an AWS API Gateway v2 configuration.
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
  source = "github.com/zachreborn/terraform-modules//modules/aws/api_gateway"

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
| [aws_apigatewayv2_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name) | resource |
| [aws_apigatewayv2_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_key_selection_expression"></a> [api\_key\_selection\_expression](#input\_api\_key\_selection\_expression) | API key selection expression for the API Gateway | `string` | `"$request.header.x-api-key"` | no |
| <a name="input_body"></a> [body](#input\_body) | OpenAPI specification for the API Gateway | `string` | `null` | no |
| <a name="input_cors_configuration"></a> [cors\_configuration](#input\_cors\_configuration) | CORS configuration for the API Gateway | <pre>object({<br/>    allow_credentials = optional(bool, false)  # Whether or not credentials are part of the CORS request.<br/>    allow_headers     = optional(list(string)) # List of allowed HTTP headers.<br/>    allow_methods     = optional(list(string)) # List of allowed methods.<br/>    allow_origins     = optional(list(string)) # List of allowed origins.<br/>    expose_headers    = optional(list(string)) # List of exposed headers in the response.<br/>    max_age           = optional(number, 0)    # Number of seconds for which the browser should cache the preflight response.<br/>  })</pre> | `{}` | no |
| <a name="input_credentials_arn"></a> [credentials\_arn](#input\_credentials\_arn) | ARN of the credentials for the API Gateway | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the API Gateway | `string` | `null` | no |
| <a name="input_disable_execute_api_endpoint"></a> [disable\_execute\_api\_endpoint](#input\_disable\_execute\_api\_endpoint) | Whether to disable the execute-api endpoint | `bool` | `false` | no |
| <a name="input_domain_names"></a> [domain\_names](#input\_domain\_names) | Map of domain names to create for the API Gateway | <pre>map(object({<br/>    domain_name_configuration = object({<br/>      certificate_arn                        = string                       # ARN of the ACM certificate to use for the custom domain name.<br/>      endpoint_type                          = optional(string, "REGIONAL") # Endpoint type. Valid values are "REGIONAL".<br/>      ownership_verification_certificate_arn = optional(string)             # ARN of the certificate to use for ownership verification.<br/>      security_policy                        = optional(string, "TLS_1_2")  # TLS version to use for the custom domain name. Valid values are "TLS_1_2".<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_fail_on_warnings"></a> [fail\_on\_warnings](#input\_fail\_on\_warnings) | Whether to fail on warnings during API Gateway creation | `bool` | `false` | no |
| <a name="input_integrations"></a> [integrations](#input\_integrations) | Map of integrations to create for the API Gateway | <pre>map(object({<br/>    connection_id             = optional(string)      # ID of the VPC link for the integration.<br/>    connection_type           = optional(string)      # Type of the VPC link for the integration. Valid values are "VPC_LINK".<br/>    content_handling_strategy = optional(string)      # How to handle request payload content type conversions. Valid values are "CONVERT_TO_BINARY" and "CONVERT_TO_TEXT".<br/>    credentials_arn           = optional(string)      # ARN of the credentials to use for the integration.<br/>    description               = optional(string)      # Description of the integration.<br/>    integration_method        = optional(string)      # HTTP method for the integration.<br/>    integration_type          = optional(string)      # Type of the integration. Valid values are "AWS", "AWS_PROXY", "HTTP", "HTTP_PROXY", "MOCK".<br/>    integration_uri           = optional(string)      # URI of the integration.<br/>    passthrough_behavior      = optional(string)      # How to handle request payload content type conversions. Valid values are "WHEN_NO_MATCH" and "WHEN_NO_TEMPLATES".<br/>    request_parameters        = optional(map(string)) # Map of request parameters for the integration.<br/>    request_templates         = optional(map(string)) # Map of request templates for the integration.<br/>    timeout_milliseconds      = optional(number)      # Timeout in milliseconds for the integration.<br/>  }))</pre> | `{}` | no |
| <a name="input_mutual_tls_authentication"></a> [mutual\_tls\_authentication](#input\_mutual\_tls\_authentication) | Mutual TLS authentication configuration for the API Gateway | <pre>object({<br/>    truststore_uri     = string           # AWS S3 bucket where the mTLS keys and certificates will be stored.<br/>    truststore_version = optional(string) # Version of the S3 object that contains the truststore. If not specified, the latest version is used. Versioning must first be enabled on the S3 bucket.<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the API Gateway | `string` | n/a | yes |
| <a name="input_protocol_type"></a> [protocol\_type](#input\_protocol\_type) | Protocol type of the API Gateway (HTTP or WEBSOCKET) | `string` | n/a | yes |
| <a name="input_route_key"></a> [route\_key](#input\_route\_key) | Route key for the API Gateway | `string` | `null` | no |
| <a name="input_route_selection_expression"></a> [route\_selection\_expression](#input\_route\_selection\_expression) | Route selection expression for the API Gateway | `string` | `"$request.method $request.path"` | no |
| <a name="input_routes"></a> [routes](#input\_routes) | Map of routes to create for the API Gateway | <pre>map(object({<br/>    api_key_required                    = optional(bool)         # Whether an API key is required for the route.<br/>    authorization_scopes                = optional(list(string)) # List of authorization scopes for the route.<br/>    authorization_type                  = optional(string)       # Type of authorization for the route. Valid values are "NONE", "AWS_IAM", "CUSTOM", "JWT".<br/>    authorizer_id                       = optional(string)       # ID of the authorizer to use for the route.<br/>    model_selection_expression          = optional(string)       # Expression to select the model for the route.<br/>    operation_name                      = optional(string)       # Operation name for the route.<br/>    request_models                      = optional(map(string))  # Map of request models for the route.<br/>    request_parameters                  = optional(map(string))  # Map of request parameters for the route.<br/>    route_key                           = optional(string)       # Route key for the route.<br/>    route_response_selection_expression = optional(string)       # Expression to select the route response for the route.<br/>    target                              = optional(string)       # Target for the route.<br/>  }))</pre> | `{}` | no |
| <a name="input_stages"></a> [stages](#input\_stages) | Map of stages to create for the API Gateway | <pre>map(object({<br/>    auto_deploy = optional(bool)   # Whether to automatically deploy the stage.<br/>    description = optional(string) # Description of the stage.<br/>    stage_name  = optional(string) # Name of the stage.<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the resources. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_target"></a> [target](#input\_target) | Target for the API Gateway | `string` | `null` | no |
| <a name="input_version"></a> [version](#input\_version) | Version identifier for the API Gateway. Must be between 1 and 64 characters in length or null. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_endpoint"></a> [api\_endpoint](#output\_api\_endpoint) | The URI of the API |
| <a name="output_api_key_selection_expression"></a> [api\_key\_selection\_expression](#output\_api\_key\_selection\_expression) | The API key selection expression for the API |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the API |
| <a name="output_cors_configuration"></a> [cors\_configuration](#output\_cors\_configuration) | The CORS configuration for the API |
| <a name="output_execution_arn"></a> [execution\_arn](#output\_execution\_arn) | The ARN prefix to be used in permission policies |
| <a name="output_id"></a> [id](#output\_id) | The API identifier |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | Map of tags assigned to the resource |
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
