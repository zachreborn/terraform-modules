# API Gateway REST API Terraform Module

Comprehensive Terraform module for creating and managing AWS API Gateway REST APIs with full feature support.

## Module Overview

This module creates AWS API Gateway REST APIs with support for all major features including methods, integrations, authorizers, usage plans, custom domains, and mTLS authentication. It follows Terraform best practices with modular design, proper resource ordering, and automatic redeployment triggers.

## Key Features

### Core API Gateway Resources
- **REST API** with configurable endpoint types (EDGE, REGIONAL, PRIVATE)
- **Resources** for defining API paths
- **Methods** with authorization and validation support
- **Method Responses** for defining expected response structures
- **Integrations** supporting Lambda, HTTP, AWS services, VPC_LINK, and MOCK
- **Integration Responses** for response mapping and transformation

### Advanced Features (Added in Latest Version)
- **Models** for request/response schema validation
- **Request Validators** for parameter and body validation
- **Authorizers** supporting Lambda (TOKEN/REQUEST) and Cognito User Pools
- **Gateway Responses** for customizing error responses
- **Usage Plans** with quotas and throttling
- **API Keys** with secure value management
- **Method Settings** for per-method logging, caching, and throttling configuration
- **Custom Domains** with optional mTLS authentication
- **Deployment Triggers** for automatic redeployment on configuration changes

## Architecture Decisions

### External Dependencies (Critical)
**ACM Certificates** and **S3 Buckets** for mTLS must be created separately to avoid circular dependencies:

1. **ACM Certificate**: Use the `acm_certificate` module separately. API Gateway requires validated certificates, and validation creates circular dependencies if done within this module.

2. **S3 Bucket for mTLS**: Use the `s3` module separately. The bucket stores the truststore.pem file and must exist before API Gateway domain configuration. Pass its name via `bucket_name`; the module builds `truststore_uri` as `s3://<bucket_name>/<mtls_config.truststore_key>` (key defaults to `truststore.pem`). An explicit `mtls_config.truststore_uri` always takes precedence.

### Deployment Strategy
The module uses a **deployment hash** to automatically trigger redeployments when any configuration changes:

```hcl
deployment_components = {
  resources              = var.resources
  methods                = var.methods
  integrations           = var.integrations
  integration_responses  = var.integration_responses
  models                 = var.models
  request_validators     = var.request_validators
  authorizers            = var.authorizers
  gateway_responses      = var.gateway_responses
  stage_variables        = var.stage_variables
  stage_description      = var.stage_description
  stage_cache_enabled    = var.cache_cluster_enabled
  stage_xray_enabled     = var.xray_tracing_enabled
  stage_method_settings  = var.method_settings
  stage_access_log       = var.access_log_settings
  stage_throttle         = var.stage_throttle_settings
}
deployment_hash = sha1(jsonencode(deployment_components))
```

This ensures API changes are automatically propagated without manual intervention.

### Resource Relationships
Resources are linked via map keys for flexibility:

- **Resources** may nest via optional `parent_resource_key` (another `resources` map key). Omitted/null parents attach under the REST API root. Nested paths like `/v1/leads` use stable logical keys (`v1`, `leads`). Nesting is implemented as separate resource addresses by depth (`this` / `nested` / `nested_2`) so parent references do not cycle the graph; max depth is two parents under a root segment (e.g. `/v1/leads/{id}`).
- **Methods** reference `resources` by key
- **Integrations** reference both `resources` and `methods` by key
- **Integration Responses** reference `resources`, `methods`, and implicitly `integrations`
- **Authorizers** can be referenced by key in method configurations
- **Request Validators** can be referenced by key in method configurations

### Import Capability
All resources use fixed names (no `name_prefix` or randomization) to support Terraform import operations.

## Variable Structure

### Map-Based Configuration
Most resources use map-based configuration for flexibility:

```hcl
resources = {
  "users" = {
    path_part = "users"
  }
  "user_id" = {
    path_part           = "{id}"
    parent_resource_key = "users"
  }
}

methods = {
  "get_users" = {
    resource      = "users"
    http_method   = "GET"
    authorization = "NONE"
  }
}

integrations = {
  "get_users_integration" = {
    resource = "users"
    method   = "get_users"
    type     = "AWS_PROXY"
    uri      = "arn:aws:apigateway:region:lambda:path/2015-03-31/functions/lambda_arn/invocations"
    integration_http_method = "POST"
  }
}
```

### Optional Fields
All non-required fields use `optional()` with sensible defaults:

```hcl
api_key_required     = optional(bool, false)
timeout_milliseconds = optional(number, 29000)
enabled              = optional(bool, true)
```

### Validation
Comprehensive validation ensures correct configuration:

- Enum values (e.g., authorizer types, response types, logging levels)
- Number ranges (e.g., cache sizes, compression sizes)
- Format validation (e.g., S3 bucket names, S3 truststore URIs and object keys)
- Null-safe checks (avoiding `length()` on nullable variables)

## Common Use Cases

### 1. Basic REST API with Lambda Integration

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
}
```

### 2. API with Request Validation

```hcl
module "api" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/api_gateway/rest_api"

  name       = "validated-api"
  stage_name = "prod"

  models = {
    "UserModel" = {
      content_type = "application/json"
      schema = jsonencode({
        type = "object"
        properties = {
          name  = { type = "string" }
          email = { type = "string", format = "email" }
        }
        required = ["name", "email"]
      })
    }
  }

  request_validators = {
    "body_validator" = {
      validate_request_body       = true
      validate_request_parameters = false
    }
  }

  methods = {
    "create_user" = {
      resource             = "users"
      http_method          = "POST"
      authorization        = "NONE"
      request_validator_id = "body_validator"
      request_models       = { "application/json" = "UserModel" }
    }
  }
}
```

### 3. API with Lambda Authorizer

```hcl
module "api" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/api_gateway/rest_api"

  name       = "secured-api"
  stage_name = "prod"

  authorizers = {
    "token_authorizer" = {
      type                             = "TOKEN"
      authorizer_uri                   = aws_lambda_function.authorizer.invoke_arn
      identity_source                  = "method.request.header.Authorization"
      authorizer_result_ttl_in_seconds = 300
    }
  }

  methods = {
    "protected_endpoint" = {
      resource       = "protected"
      http_method    = "GET"
      authorization  = "CUSTOM"
      authorizer_id  = "token_authorizer"
    }
  }
}
```

### 4. API with Usage Plans and API Keys

```hcl
module "api" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/api_gateway/rest_api"

  name       = "metered-api"
  stage_name = "prod"

  usage_plans = {
    "basic_plan" = {
      name = "Basic Plan"
      api_stages = [{ stage_name = "prod" }]
      quota_settings = {
        limit  = 1000
        period = "DAY"
      }
      throttle_settings = {
        burst_limit = 10
        rate_limit  = 5
      }
    }
  }

  api_keys = {
    "customer_key" = {
      name    = "Customer API Key"
      enabled = true
    }
  }

  usage_plan_keys = {
    "basic_customer" = {
      usage_plan_key = "basic_plan"
      api_key_key    = "customer_key"
    }
  }

  methods = {
    "metered_endpoint" = {
      resource         = "data"
      http_method      = "GET"
      authorization    = "NONE"
      api_key_required = true
    }
  }
}
```

### 5. API with Custom Domain and mTLS

```hcl
# Create ACM certificate separately
module "certificate" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/acm_certificate"
  
  domain_name       = "api.example.com"
  validation_method = "DNS"
}

# Create S3 bucket for truststore separately
module "truststore_bucket" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/s3"
  
  bucket = "my-api-truststore"
  versioning_enabled = true
}

# Upload truststore.pem to S3 (outside Terraform or via aws_s3_object)

# Create API Gateway with mTLS
module "api" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/api_gateway/rest_api"

  name       = "secure-api"
  stage_name = "prod"

  domain_name     = "api.example.com"
  certificate_arn = module.certificate.arn
  enable_mtls     = true

  # truststore_uri resolves to s3://my-api-truststore/truststore/truststore.pem
  bucket_name = "my-api-truststore"
  mtls_config = {
    truststore_key     = "truststore/truststore.pem" # Optional. Defaults to "truststore.pem"
    truststore_version = "version_id_from_s3"         # Optional
  }

  # Alternative: pass the full URI instead of bucket_name + truststore_key.
  # mtls_config = {
  #   truststore_uri = "s3://my-api-truststore/truststore/truststore.pem"
  # }
}
```

### 6. API with CloudWatch Logging and X-Ray

```hcl
module "api" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/api_gateway/rest_api"

  name       = "monitored-api"
  stage_name = "prod"

  xray_tracing_enabled = true

  access_log_settings = {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  method_settings = {
    "all_methods" = {
      method_path        = "*/*"
      metrics_enabled    = true
      logging_level      = "INFO"
      data_trace_enabled = true
    }
  }
}
```

## Provider Requirements

- **Terraform / OpenTofu**: >= 1.3.0 (`optional()` object attributes)
- **AWS Provider**: >= 6.0.0

## Testing

To validate the module:

```bash
cd modules/aws/api_gateway/rest_api
terraform init -upgrade
terraform validate
terraform fmt -check
```

## Migration Notes

### From Previous Versions

If migrating from an earlier version of this module:

1. **ACM Certificate**: If the module was creating ACM certificates, these must be moved to a separate `acm_certificate` module.

2. **S3 Buckets**: If the module was creating S3 buckets for mTLS, these must be moved to a separate `s3` module.

3. **New Variables**: Review new variables for models, authorizers, request validators, usage plans, API keys, gateway responses, and method settings.

4. **enable_mtls**: Now defaults to `false` instead of `true`.

## Outputs

The module provides comprehensive outputs for all created resources:

- API details (id, name, execution_arn, root_resource_id)
- All created resources (resources, methods, integrations, etc.)
- Stage information (stage_name, stage_invoke_url, stage_execution_arn)
- Domain configuration (if configured)
- Usage plans and API keys (sensitive values marked appropriately)

## Security Considerations

1. **API Keys**: Values are marked sensitive and excluded from default outputs
2. **mTLS**: Requires external S3 bucket and truststore management
3. **Authorizers**: Support for Lambda and Cognito provides flexible authentication
4. **Request Validation**: Models and validators prevent invalid requests
5. **Logging**: Access logs should be encrypted at rest in CloudWatch

## Known Limitations

1. **OpenAPI/Swagger Import**: The `body` parameter supports OpenAPI nested paths, but that surface should not be mixed casually with the typed `resources` / `methods` / `integrations` maps. Prefer `parent_resource_key` for map-based nested paths.
2. **Deployment Stages**: Currently supports a single stage per module instance
3. **VPC Link**: V1 VPC Links only (for REST APIs); use the v2 module for HTTP APIs
4. **Parent cycles**: Unknown and self `parent_resource_key` values fail variable validation. Longer cycles are rejected by the OpenTofu dependency graph.

## Contributing

When contributing to this module:

1. Follow existing variable naming and structure conventions
2. Use `optional()` for non-required fields with sensible defaults
3. Add validation for enum values and ranges
4. Update examples and documentation
5. Ensure `terraform fmt` passes
6. Test with representative configurations

## References

- [AWS API Gateway REST API Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-rest-api.html)
- [Terraform AWS Provider - API Gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api)
- [API Gateway mTLS](https://docs.aws.amazon.com/apigateway/latest/developerguide/rest-api-mutual-tls.html)
