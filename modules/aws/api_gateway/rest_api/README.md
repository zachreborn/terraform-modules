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

### Basic REST API with Lambda Integration

```hcl
module "api" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/api_gateway/rest_api"

  name       = "my-api"
  stage_name = "prod"

  resources = {
    "items" = { path_part = "items" }
  }

  methods = {
    "get_items" = {
      resource      = "items"
      http_method   = "GET"
      authorization = "NONE"
    }
  }

  integrations = {
    "get_items_lambda" = {
      resource                = "items"
      method                  = "get_items"
      type                    = "AWS_PROXY"
      uri                     = aws_lambda_function.items.invoke_arn
      integration_http_method = "POST"
    }
  }

  tags = {
    terraform   = "true"
    environment = "prod"
  }
}
```

### REST API with mTLS Custom Domain

**Note**: ACM certificate and S3 bucket must be created separately to avoid circular dependencies.

```hcl
# Create ACM certificate first
module "api_certificate" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/acm_certificate"
  
  domain_name       = "api.example.com"
  validation_method = "DNS"
}

# Create S3 bucket for truststore
module "truststore_bucket" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/s3/bucket"
  
  bucket_prefix     = "api-mtls-truststore-"
  versioning_status = "Enabled"
}

# Upload truststore to S3
resource "aws_s3_object" "truststore" {
  bucket = module.truststore_bucket.s3_bucket_id
  key    = "truststore.pem"
  source = "path/to/truststore.pem"
  etag   = filemd5("path/to/truststore.pem")
}

# Create API Gateway with mTLS
module "api" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/api_gateway/rest_api"

  name        = "secure-api"
  stage_name  = "prod"
  domain_name = "api.example.com"
  
  # mTLS Configuration
  certificate_arn = module.api_certificate.arn
  enable_mtls     = true
  bucket_name     = module.truststore_bucket.s3_bucket_id
  mtls_config = {
    truststore_uri     = "s3://${module.truststore_bucket.s3_bucket_id}/truststore.pem"
    truststore_version = null  # Uses latest version
  }

  # REST API configuration
  resources = {
    "test" = { path_part = "test" }
  }

  methods = {
    "get_test" = {
      resource      = "test"
      http_method   = "GET"
      authorization = "NONE"
    }
  }

  integrations = {
    "get_test_integration" = {
      resource                = "test"
      method                  = "get_test"
      type                    = "HTTP_PROXY"
      uri                     = "http://backend.internal:5000/test"
      integration_http_method = "GET"
      connection_type         = "VPC_LINK"
      vpc_link_key            = "backend-vpc-link"
    }
  }

  vpc_links = {
    "backend-vpc-link" = {
      description = "VPC Link to internal backend"
      target_arns = [aws_lb.backend_nlb.arn]
    }
  }

  tags = {
    terraform   = "true"
    environment = "prod"
  }
}
```

### Testing mTLS Connectivity

Once deployed, test your mTLS-enabled API:

**With client certificate (should succeed):**
```bash
curl --key my_client.key --cert my_client.pem \
  --location -o /dev/null -s -w "%{http_code}" \
  'https://api.example.com/test'
```

**Without client certificate (should fail):**
```bash
curl 'https://api.example.com/test' -v
```

**Verbose response with certificate:**
```bash
curl --key my_client.key --cert my_client.pem \
  'https://api.example.com/test' --data '' -v
```

_For more comprehensive examples including request validation, authorizers, and usage plans, please refer to [WARP.md](./WARP.md)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.14.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_api_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_api_key) | resource |
| [aws_api_gateway_authorizer.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_authorizer) | resource |
| [aws_api_gateway_base_path_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |
| [aws_api_gateway_gateway_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_gateway_response) | resource |
| [aws_api_gateway_integration.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_method.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_method_settings.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_model.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_model) | resource |
| [aws_api_gateway_request_validator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_request_validator) | resource |
| [aws_api_gateway_resource.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_api_gateway_usage_plan.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan) | resource |
| [aws_api_gateway_usage_plan_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_usage_plan_key) | resource |
| [aws_api_gateway_vpc_link.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_vpc_link) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_log_settings"></a> [access\_log\_settings](#input\_access\_log\_settings) | Access log settings for the stage | <pre>object({<br/>    destination_arn = string # ARN of CloudWatch Logs log group or Kinesis Data Firehose delivery stream<br/>    format          = string # Log format<br/>  })</pre> | `null` | no |
| <a name="input_api_key_source"></a> [api\_key\_source](#input\_api\_key\_source) | The source of the API key for metering requests. Valid values are 'HEADER' and 'AUTHORIZER'. | `string` | `"HEADER"` | no |
| <a name="input_api_keys"></a> [api\_keys](#input\_api\_keys) | A map of API keys | <pre>map(object({<br/>    name        = string<br/>    description = optional(string)<br/>    enabled     = optional(bool, true)<br/>    value       = optional(string) # Custom key value, generated if not provided<br/>  }))</pre> | `{}` | no |
| <a name="input_authorizers"></a> [authorizers](#input\_authorizers) | A map of authorizers for the API. | <pre>map(object({<br/>    type                             = string                 # TOKEN, REQUEST, or COGNITO_USER_POOLS<br/>    authorizer_uri                   = optional(string)       # Required for Lambda authorizers<br/>    authorizer_credentials           = optional(string)       # IAM role ARN for invoking authorizer<br/>    identity_source                  = optional(string)       # Source of the identity in the request<br/>    identity_validation_expression   = optional(string)       # Regex for validating identity source<br/>    authorizer_result_ttl_in_seconds = optional(number, 300)  # TTL for cached authorizer results (0-3600)<br/>    provider_arns                    = optional(list(string)) # Required for COGNITO_USER_POOLS<br/>  }))</pre> | `{}` | no |
| <a name="input_base_path"></a> [base\_path](#input\_base\_path) | Base path mapping for the custom domain | `string` | `null` | no |
| <a name="input_binary_media_types"></a> [binary\_media\_types](#input\_binary\_media\_types) | A list of binary media types supported by the Rest API. | `list(string)` | `[]` | no |
| <a name="input_body"></a> [body](#input\_body) | The body of the API definition in JSON format. | `string` | `null` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the S3 bucket for mTLS truststore. This is a reference only - the bucket must be created separately using the s3 module. | `string` | `null` | no |
| <a name="input_cache_cluster_enabled"></a> [cache\_cluster\_enabled](#input\_cache\_cluster\_enabled) | Specifies whether a cache cluster is enabled for the stage | `bool` | `false` | no |
| <a name="input_cache_cluster_size"></a> [cache\_cluster\_size](#input\_cache\_cluster\_size) | The size of the cache cluster for the stage, if enabled. Valid values are 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237 | `string` | `"0.5"` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ARN of the ACM certificate for the custom domain. Must be created separately using the acm\_certificate module. | `string` | `null` | no |
| <a name="input_client_certificate_id"></a> [client\_certificate\_id](#input\_client\_certificate\_id) | The identifier of a client certificate for the stage | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | A description of the API. | `string` | `null` | no |
| <a name="input_disable_execute_api_endpoint"></a> [disable\_execute\_api\_endpoint](#input\_disable\_execute\_api\_endpoint) | Specifies whether the execute API endpoint is disabled. Defaults to false. | `bool` | `false` | no |
| <a name="input_documentation_version"></a> [documentation\_version](#input\_documentation\_version) | The version of the associated API documentation | `string` | `null` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Custom domain name for the API Gateway. Required for mTLS. | `string` | `null` | no |
| <a name="input_enable_mtls"></a> [enable\_mtls](#input\_enable\_mtls) | Enable mTLS configuration for the API Gateway | `bool` | `false` | no |
| <a name="input_endpoint_configuration"></a> [endpoint\_configuration](#input\_endpoint\_configuration) | The endpoint configuration for the API. This is a complex object. | <pre>object({<br/>    types            = list(string)           # List of endpoint types. Valid values are 'EDGE', 'REGIONAL', and 'PRIVATE'.<br/>    vpc_endpoint_ids = optional(list(string)) # List of VPC endpoint IDs for private endpoints. Only supported if the type is 'PRIVATE'.<br/>  })</pre> | `null` | no |
| <a name="input_endpoint_configuration_types"></a> [endpoint\_configuration\_types](#input\_endpoint\_configuration\_types) | List of endpoint types for the custom domain. Valid values: EDGE, REGIONAL, PRIVATE | `list(string)` | <pre>[<br/>  "REGIONAL"<br/>]</pre> | no |
| <a name="input_fail_on_warnings"></a> [fail\_on\_warnings](#input\_fail\_on\_warnings) | Specifies whether to fail on warnings when creating the API. Defaults to false. | `bool` | `false` | no |
| <a name="input_gateway_responses"></a> [gateway\_responses](#input\_gateway\_responses) | A map of gateway responses for the API. | <pre>map(object({<br/>    response_type       = string<br/>    status_code         = optional(string)<br/>    response_parameters = optional(map(string))<br/>    response_templates  = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_integration_responses"></a> [integration\_responses](#input\_integration\_responses) | A map of integration responses for the API. | <pre>map(object({<br/>    resource            = string # The resource key<br/>    method              = string # The method key<br/>    status_code         = string<br/>    selection_pattern   = optional(string)<br/>    response_parameters = optional(map(string))<br/>    response_templates  = optional(map(string))<br/>    content_handling    = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_integrations"></a> [integrations](#input\_integrations) | A map of integrations for the API. | <pre>map(object({<br/>    type                    = string<br/>    uri                     = string<br/>    resource                = string # The resource key<br/>    method                  = string # The method key<br/>    integration_http_method = optional(string)<br/>    credentials             = optional(string)<br/>    connection_type         = optional(string)<br/>    connection_id           = optional(string)<br/>    vpc_link_key            = optional(string) # The VPC Link key from vpc_links variable<br/>    request_parameters      = optional(map(string))<br/>    request_templates       = optional(map(string))<br/>    passthrough_behavior    = optional(string)<br/>    content_handling        = optional(string)<br/>    timeout_milliseconds    = optional(number, 29000)<br/>    cache_key_parameters    = optional(list(string))<br/>    cache_namespace         = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_method_responses"></a> [method\_responses](#input\_method\_responses) | A map of method responses for the API. | <pre>map(object({<br/>    resource            = string # The resource key this method response belongs to<br/>    method              = string # The method key this response belongs to<br/>    status_code         = string<br/>    response_models     = optional(map(string))<br/>    response_parameters = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_method_settings"></a> [method\_settings](#input\_method\_settings) | A map of method settings for specific resource/method paths | <pre>map(object({<br/>    method_path                                = string<br/>    metrics_enabled                            = optional(bool, false)<br/>    logging_level                              = optional(string, "OFF")<br/>    data_trace_enabled                         = optional(bool, false)<br/>    throttling_burst_limit                     = optional(number, -1)<br/>    throttling_rate_limit                      = optional(number, -1)<br/>    caching_enabled                            = optional(bool, false)<br/>    cache_ttl_in_seconds                       = optional(number, 300)<br/>    cache_data_encrypted                       = optional(bool, false)<br/>    require_authorization_for_cache_control    = optional(bool, false)<br/>    unauthorized_cache_control_header_strategy = optional(string, "SUCCEED_WITH_RESPONSE_HEADER")<br/>  }))</pre> | `{}` | no |
| <a name="input_methods"></a> [methods](#input\_methods) | A map of methods to create for the API. Each key is a unique identifier for the method. | <pre>map(object({<br/>    resource             = string # The resource key this method belongs to<br/>    http_method          = string<br/>    authorization        = string<br/>    authorizer_id        = optional(string) # Can be authorizer key or ARN<br/>    authorization_scopes = optional(list(string))<br/>    api_key_required     = optional(bool, false)<br/>    operation_name       = optional(string)<br/>    request_models       = optional(map(string))<br/>    request_parameters   = optional(map(string))<br/>    request_validator_id = optional(string) # Can be validator key or ID<br/>  }))</pre> | `{}` | no |
| <a name="input_minimum_compression_size"></a> [minimum\_compression\_size](#input\_minimum\_compression\_size) | The minimum compression size in bytes. Must be either an integer between -1 and 10485760 or set to null. Defaults to null, which disables compression. | `number` | `null` | no |
| <a name="input_models"></a> [models](#input\_models) | A map of models for the API. Each key is the model name. | <pre>map(object({<br/>    content_type = string<br/>    description  = optional(string)<br/>    schema       = string # JSON schema as a string<br/>  }))</pre> | `{}` | no |
| <a name="input_mtls_config"></a> [mtls\_config](#input\_mtls\_config) | mTLS configuration for the custom domain. S3 bucket and truststore must be created separately. Required when enable\_mtls is true and domain\_name is provided. | <pre>object({<br/>    truststore_uri     = string           # S3 URI to the truststore file (e.g., s3://bucket-name/path/to/truststore.pem)<br/>    truststore_version = optional(string) # Version of the truststore file (use S3 object version_id)<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the API. This is required. | `string` | n/a | yes |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | A map of API Gateway-specific parameters that can be used to configure the API. | `map(string)` | `{}` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | The resource policy for the API in JSON format. | `string` | `null` | no |
| <a name="input_put_rest_api_mode"></a> [put\_rest\_api\_mode](#input\_put\_rest\_api\_mode) | The mode for the PUT Rest API operation. Valid values are 'merge' and 'overwrite'. | `string` | `"overwrite"` | no |
| <a name="input_request_validators"></a> [request\_validators](#input\_request\_validators) | A map of request validators for the API. | <pre>map(object({<br/>    validate_request_body       = bool<br/>    validate_request_parameters = bool<br/>    name                        = optional(string) # Defaults to map key if not provided<br/>  }))</pre> | `{}` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | A map of resources to create under the API. Each key is the resource path and the value is a map of resource settings. | <pre>map(object({<br/>    path_part = string<br/>  }))</pre> | `{}` | no |
| <a name="input_root_integrations"></a> [root\_integrations](#input\_root\_integrations) | A map of integrations for methods on the root resource. | <pre>map(object({<br/>    type                    = string<br/>    uri                     = optional(string)<br/>    method                  = string # The root_method key<br/>    integration_http_method = optional(string)<br/>    credentials             = optional(string)<br/>    connection_type         = optional(string)<br/>    connection_id           = optional(string)<br/>    vpc_link_key            = optional(string) # The VPC Link key from vpc_links variable<br/>    request_parameters      = optional(map(string))<br/>    request_templates       = optional(map(string))<br/>    passthrough_behavior    = optional(string)<br/>    content_handling        = optional(string)<br/>    timeout_milliseconds    = optional(number, 29000)<br/>    cache_key_parameters    = optional(list(string))<br/>    cache_namespace         = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_root_methods"></a> [root\_methods](#input\_root\_methods) | A map of methods to create on the root resource. Each key is a unique identifier for the method. | <pre>map(object({<br/>    http_method          = string<br/>    authorization        = string<br/>    authorizer_id        = optional(string) # Can be authorizer key or ARN<br/>    authorization_scopes = optional(list(string))<br/>    api_key_required     = optional(bool, false)<br/>    operation_name       = optional(string)<br/>    request_models       = optional(map(string))<br/>    request_parameters   = optional(map(string))<br/>    request_validator_id = optional(string) # Can be validator key or ID<br/>  }))</pre> | `{}` | no |
| <a name="input_security_policy"></a> [security\_policy](#input\_security\_policy) | Security policy for the custom domain. Valid values: TLS\_1\_0, TLS\_1\_2 | `string` | `"TLS_1_2"` | no |
| <a name="input_stage_description"></a> [stage\_description](#input\_stage\_description) | Description of the stage | `string` | `null` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | Name of the stage | `string` | n/a | yes |
| <a name="input_stage_throttle_settings"></a> [stage\_throttle\_settings](#input\_stage\_throttle\_settings) | Stage-level throttle settings | <pre>object({<br/>    burst_limit = number<br/>    rate_limit  = number<br/>  })</pre> | `null` | no |
| <a name="input_stage_variables"></a> [stage\_variables](#input\_stage\_variables) | A map of stage variables | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the API. | `map(string)` | `{}` | no |
| <a name="input_usage_plan_keys"></a> [usage\_plan\_keys](#input\_usage\_plan\_keys) | A map of usage plan key associations | <pre>map(object({<br/>    usage_plan_key = string # Key from usage_plans<br/>    api_key_key    = string # Key from api_keys<br/>  }))</pre> | `{}` | no |
| <a name="input_usage_plans"></a> [usage\_plans](#input\_usage\_plans) | A map of usage plans for the API | <pre>map(object({<br/>    name        = string<br/>    description = optional(string)<br/>    api_stages = list(object({<br/>      stage_name = string<br/>    }))<br/>    quota_settings = optional(object({<br/>      limit  = number<br/>      offset = optional(number, 0)<br/>      period = string # DAY, WEEK, or MONTH<br/>    }))<br/>    throttle_settings = optional(object({<br/>      burst_limit = number<br/>      rate_limit  = number<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_links"></a> [vpc\_links](#input\_vpc\_links) | A map of VPC links for the API. Each key is the name of the VPC link. | <pre>map(object({<br/>    description = string<br/>    target_arns = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_xray_tracing_enabled"></a> [xray\_tracing\_enabled](#input\_xray\_tracing\_enabled) | Whether active tracing with X-ray is enabled | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | ID of the REST API |
| <a name="output_api_key_values"></a> [api\_key\_values](#output\_api\_key\_values) | API key values (sensitive) - only use when necessary |
| <a name="output_api_keys"></a> [api\_keys](#output\_api\_keys) | API Gateway API keys created |
| <a name="output_api_name"></a> [api\_name](#output\_api\_name) | Name of the REST API |
| <a name="output_authorizers"></a> [authorizers](#output\_authorizers) | API Gateway authorizers created |
| <a name="output_base_path_mapping_id"></a> [base\_path\_mapping\_id](#output\_base\_path\_mapping\_id) | ID of the base path mapping |
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | ARN of the ACM certificate used (from input variable) |
| <a name="output_created_date"></a> [created\_date](#output\_created\_date) | Creation date of the REST API |
| <a name="output_deployment_id"></a> [deployment\_id](#output\_deployment\_id) | ID of the API Gateway deployment |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | Domain name of the API Gateway (if configured) |
| <a name="output_domain_name_arn"></a> [domain\_name\_arn](#output\_domain\_name\_arn) | ARN of the domain name |
| <a name="output_domain_name_hosted_zone_id"></a> [domain\_name\_hosted\_zone\_id](#output\_domain\_name\_hosted\_zone\_id) | Hosted zone ID for the API Gateway custom domain (for Route53 alias) |
| <a name="output_domain_name_id"></a> [domain\_name\_id](#output\_domain\_name\_id) | Internal identifier of the domain name |
| <a name="output_domain_name_target_domain_name"></a> [domain\_name\_target\_domain\_name](#output\_domain\_name\_target\_domain\_name) | Target domain name for the API Gateway custom domain (for DNS alias) |
| <a name="output_execution_arn"></a> [execution\_arn](#output\_execution\_arn) | Execution ARN of the REST API |
| <a name="output_gateway_responses"></a> [gateway\_responses](#output\_gateway\_responses) | API Gateway gateway responses created |
| <a name="output_integration_responses"></a> [integration\_responses](#output\_integration\_responses) | API Gateway integration responses created |
| <a name="output_integrations"></a> [integrations](#output\_integrations) | API Gateway integrations created |
| <a name="output_method_responses"></a> [method\_responses](#output\_method\_responses) | API Gateway method responses created |
| <a name="output_method_settings"></a> [method\_settings](#output\_method\_settings) | API Gateway method settings created |
| <a name="output_methods"></a> [methods](#output\_methods) | API Gateway methods created |
| <a name="output_models"></a> [models](#output\_models) | API Gateway models created |
| <a name="output_mtls_enabled"></a> [mtls\_enabled](#output\_mtls\_enabled) | Whether mTLS is enabled |
| <a name="output_request_validators"></a> [request\_validators](#output\_request\_validators) | API Gateway request validators created |
| <a name="output_resources"></a> [resources](#output\_resources) | API Gateway resources created |
| <a name="output_root_integrations"></a> [root\_integrations](#output\_root\_integrations) | API Gateway root resource integrations created |
| <a name="output_root_methods"></a> [root\_methods](#output\_root\_methods) | API Gateway root resource methods created |
| <a name="output_root_resource_id"></a> [root\_resource\_id](#output\_root\_resource\_id) | Resource ID of the REST API root resource |
| <a name="output_stage_arn"></a> [stage\_arn](#output\_stage\_arn) | ARN of the API Gateway stage |
| <a name="output_stage_execution_arn"></a> [stage\_execution\_arn](#output\_stage\_execution\_arn) | Execution ARN to be used in Lambda permissions |
| <a name="output_stage_id"></a> [stage\_id](#output\_stage\_id) | ID of the API Gateway stage |
| <a name="output_stage_invoke_url"></a> [stage\_invoke\_url](#output\_stage\_invoke\_url) | Invoke URL for the API Gateway stage |
| <a name="output_stage_name"></a> [stage\_name](#output\_stage\_name) | Name of the API Gateway stage |
| <a name="output_truststore_uri"></a> [truststore\_uri](#output\_truststore\_uri) | S3 URI of the truststore file used for mTLS (from configuration) |
| <a name="output_truststore_version"></a> [truststore\_version](#output\_truststore\_version) | Version of the truststore file used for mTLS (from configuration) |
| <a name="output_usage_plan_keys"></a> [usage\_plan\_keys](#output\_usage\_plan\_keys) | API Gateway usage plan key associations created |
| <a name="output_usage_plans"></a> [usage\_plans](#output\_usage\_plans) | API Gateway usage plans created |
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
