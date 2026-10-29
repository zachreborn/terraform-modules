# API Gateway v2

Manages one Amazon API Gateway v2 HTTP or WebSocket API and keyed collections
of integrations, routes, stages, authorizers, domains, models, responses and
VPC links. The REST API module is separate. No deployment, API mapping, Lambda,
permission, role, certificate, DNS record or log group is created implicitly.

## Prerequisites and versions

- OpenTofu is the default runner. The module language minimum is Terraform
  1.3.0 (optional object defaults; also covers resource preconditions).
- AWS provider `hashicorp/aws >= 6.29.0`: domain `routing_mode` first appears in
  6.29.0; address-family controls predate that floor and resource region
  overrides are available since 6.0.0.
- Mocked native tests require OpenTofu 1.9+ (or Terraform 1.7+). The suite is
  also verified unchanged with Terraform 1.10.0; the module uses no post-fork
  language features.
- Provision Lambda functions and their API Gateway invocation permissions,
  access-log destinations and required logging permissions separately.
  Custom domains require certificates, an optional external S3 truststore,
  DNS and API mappings. Private integrations require existing networking.
  WebSocket execution logging needs the caller's API Gateway account logging
  role configuration.

The immutable coverage baseline is the
[6.29.0 provider source](https://github.com/hashicorp/terraform-provider-aws/tree/v6.29.0/internal/service/apigatewayv2),
cross-checked with the [registry documentation](https://registry.terraform.io/providers/hashicorp/aws/6.29.0/docs/resources/apigatewayv2_api).

## HTTP webhook usage

The required adoption shape explicitly retains integration method POST, payload
2.0, application-managed authentication and auto-deployment. Identifiers below
are fake; substitute existing caller resources. Pin `source` to the eventual
released tag or reviewed commit (`?ref=<release-tag-or-commit>`); no future
release tag is assumed here.

```hcl
module "http" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/api_gateway/v2"

  name          = "webhook"
  protocol_type = "HTTP"

  integrations = {
    webhook = {
      integration_type       = "AWS_PROXY"
      integration_method     = "POST"
      integration_uri        = "arn:aws:lambda:us-east-1:123456789012:function:fake-webhook"
      payload_format_version = "2.0"
    }
  }
  routes = {
    webhook = {
      route_key          = "POST /webhook/{token}"
      authorization_type = "NONE"
      integration_key    = "webhook"
    }
  }
  stages = {
    "$default" = {
      auto_deploy = true
      access_log_settings = {
        destination_arn = "arn:aws:logs:us-east-1:123456789012:log-group:fake-access"
        format = jsonencode({
          requestId      = "$context.requestId"
          status         = "$context.status"
          responseLength = "$context.responseLength"
          latency        = "$context.responseLatency"
        })
      }
    }
  }
}
```

The log format deliberately excludes path, raw path, route key, request body,
headers and authorization data: a token-bearing route must not leak into logs.
`NONE` does not implement authentication; the application must validate tokens.
Logging is opt-in to preserve existing defaults, but enabled in this example.

## Scalable map/YAML configuration

Collection keys are stable state identities, not display names. A single module
can consume multiple integrations, routes and stages without repeated declarations:

```hcl
locals {
  http = yamldecode(file("${path.module}/http.yaml"))
}

module "http" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/api_gateway/v2"

  name          = local.http.name
  protocol_type = "HTTP"
  integrations  = local.http.integrations
  routes        = local.http.routes
  stages        = local.http.stages
}
```

```yaml
name: application
integrations:
  primary:
    integration_type: HTTP_PROXY
    integration_method: ANY
    integration_uri: https://primary.example.invalid
  secondary:
    integration_type: HTTP_PROXY
    integration_method: ANY
    integration_uri: https://secondary.example.invalid
routes:
  primary:
    route_key: ANY /primary
    integration_key: primary
    authorization_type: AWS_IAM
  secondary:
    route_key: ANY /secondary
    integration_key: secondary
    authorization_type: AWS_IAM
stages:
  staging:
    auto_deploy: true
  production:
    auto_deploy: true
    access_log_settings:
      destination_arn: arn:aws:logs:us-east-1:123456789012:log-group:fake-access
      format: '{"requestId":"$context.requestId","status":"$context.status"}'
```

## Design decisions and compatibility repairs

- All resource maps accept `{}` or explicit null as empty. Null map elements
  fail validation. Optional nested blocks are absent when null.
- Default CORS expands to false credentials, zero max age and null lists.
  False/zero-only and null/empty-list configurations omit the provider block.
  Meaningful CORS requires HTTP and conflicts with OpenAPI `body`.
- `body` owns routes/integrations; do not also configure those maps, CORS,
  `api_version`, or quick-create settings. `target` quick create owns an
  integration, route and default stage; do not overlap those explicit maps.
- Defaults remain payload format **1.0**, connection type **INTERNET**, stage
  auto-deploy **false**, execute-api endpoint enabled, fail-on-warnings false,
  route selection `$request.method $request.path`, API key selection
  `$request.header.x-api-key`, and shared tags `{ terraform = "true" }`.
  WebSocket callers usually override route selection to `$request.body.action`.
- Physical authorizer/model/stage names remain their map keys. Legacy
  `authorizers[*].name`, required `models[*].name`, and `stages[*].stage_name`
  are deprecated no-op aliases, even when different. Authorizer
  `provider_arns`, `scopes` and `token_validation_expression` remain deprecated
  no-ops: they are not v2 provider arguments. Use route authorization scopes
  or the appropriate authentication system instead.
- `authorizer_result_ttl_in_seconds` takes precedence over the legacy
  `authorizer_result_ttl`; zero disables caching and is not lost. Unequal
  simultaneous values fail validation. Nested JWT and domain mutual TLS
  configuration takes precedence over global fallback; conflicting duplicates
  fail. Global JWT is ignored for REQUEST and is never emitted as an empty
  block. HTTP REQUEST authorizers require a payload version; simple responses
  require 2.0. JWT authorizers require audience and issuer.
- Route `request_parameter` is the canonical typed block map. Deprecated
  plural `request_parameters` accepts parameter-key => `"true"`/`"false"` and
  converts those strings to booleans. Do not supply both nonempty maps.
  These parameters and model/response resources are WebSocket-only. HTTP
  stages support access logs, metrics and throttling, not execution logging
  level or data tracing; explicit incompatible requests fail instead of
  silently disappearing.
- Internal `integration_key`, `authorizer_key` and `vpc_link_key` resolve
  existing map keys. Literal targets retain `integrations/<id>`. Optional
  references may omit both forms; response parents require exactly one ID or
  key. Route-response `route_key` is a **logical parent map key**, not the
  actual HTTP/WebSocket route string. Guarded references report precondition
  errors, not invalid-index diagnostics.
- `region` is applied to every resource. Taggable resources merge a generated
  Name, then shared tags, then supported per-entry stage/VPC-link tags.
  Caller values win. The additive Name tag and repaired per-link tags can
  cause in-place tag updates for legacy callers.
- Provider-shaped `cors_configuration` output is preserved. Keyed ID/ARN,
  invoke URL, tag and domain outputs retain caller keys; absent resources
  return empty maps. No unsupported provider arguments or lifecycle ignores
  are introduced.

### Release and adoption considerations

The AWS floor increase from 4.0.0 to 6.29.0 and language floor increase from
1.0.0 to 1.3.0 are **breaking toolchain changes** under repository versioning.
Ship the combined existing-module changes in a major release unless maintainers
split them. New capabilities are additive; previously ignored nested schemas,
TTL, stage descriptions/logging and tags now take effect. Malformed values and
conflicting ownership/protocol settings now fail intentionally.

Preserve physical names, API protocol, integration URI/method/payload,
authorization, stage auto-deploy/logging and every keyed address during adoption.
API protocol and quick-create credentials/route_key/target, integration type
and subtype, stage name, domain name, and VPC-link networking can be ForceNew
under the provider schema. Review plans before changing them; aliases must not
be used to rename existing keyed resources. Do not use `ignore_changes` or
destroy/recreate as an adoption procedure.

## Declarative moves and imports

For resources **already in the same state**, use these copyable address moves
alongside the HTTP example and remove the old resource declarations:

```hcl
moved {
  from = aws_apigatewayv2_api.webhook
  to   = module.http.aws_apigatewayv2_api.this
}
moved {
  from = aws_apigatewayv2_integration.webhook
  to   = module.http.aws_apigatewayv2_integration.this["webhook"]
}
moved {
  from = aws_apigatewayv2_route.webhook
  to   = module.http.aws_apigatewayv2_route.this["webhook"]
}
moved {
  from = aws_apigatewayv2_stage.webhook
  to   = module.http.aws_apigatewayv2_stage.this["$default"]
}
```

The remaining unchanged keyed address inventory (substitute each actual key):

- `module.http.aws_apigatewayv2_authorizer.this["key"]`
- `module.http.aws_apigatewayv2_domain_name.this["api.example.invalid"]`
- `module.http.aws_apigatewayv2_integration_response.this["key"]`
- `module.http.aws_apigatewayv2_model.this["key"]`
- `module.http.aws_apigatewayv2_route_response.this["key"]`
- `module.http.aws_apigatewayv2_vpc_link.this["key"]`

Use imports only for resources **not already in state**, never to manage the
same remote object twice. Import identifiers from provider 6.29.0:

- API: `api-id`
- Integration, route, authorizer, model: `api-id/resource-id`
- Stage: `api-id/stage-name` (including literal `$default`)
- Integration response: `api-id/integration-id/integration-response-id`
- Route response: `api-id/route-id/route-response-id`
- Domain: the domain name
- VPC link: the VPC-link ID

For example, with Terraform 1.5+ import-block support (CLI import is available
at the module's lower language floor):

```hcl
import {
  to = module.http.aws_apigatewayv2_api.this
  id = "api123"
}
import {
  to = module.http.aws_apigatewayv2_integration.this["webhook"]
  id = "api123/int123"
}
import {
  to = module.http.aws_apigatewayv2_route.this["webhook"]
  id = "api123/route123"
}
import {
  to = module.http.aws_apigatewayv2_stage.this["$default"]
  id = "api123/$default"
}
```

Quick-create managed integration/route resources cannot be imported as
independently managed resources. Pin a reviewed release/commit and require
no unintended destroys or replacements in the consumer's own plan. Offline
mock tests verify configuration/wiring, not any production state or delivery
guarantee. Cross-module adoption/migration fixtures are maintained separately.

## Offline validation
Authorizer cache TTL inputs (both aliases, including explicit zero) are supported
only for HTTP REQUEST authorizers, as specified by the
[AWS authorizer API](https://docs.aws.amazon.com/apigatewayv2/latest/api-reference/apis-apiid-authorizers.html).
Ownership guards live on integrations, routes and stages so callers can pass
API-dependent child inputs and externally managed deployment IDs without cycles.

```sh
tofu init -backend=false
tofu validate
tofu test
tofu fmt -check -diff -recursive
terraform-docs markdown table --output-file README.md --output-mode inject .
```

Native tests mock every AWS resource and use only fake external identifiers.
No backend, AWS credentials, AWS data source, or cloud request is needed.
Deterministic mocked apply cases verify computed outputs; plan cases cover
optional settings, null maps, legacy compatibility and each validation failure.
Security scanning uses the repository `.checkov.yaml`; caller-selected
authorization and logging remain configurable, with no new suppressions.
### Cross-module adoption and migration verification

From this module directory, run:

```sh
python3 tests/verify_adoption.py
python3 -B -m unittest discover -s tests -p 'test_verify_adoption.py'
```

The native `tests/adoption.tftest.hcl` fixture composes the real table, queue,
mapping and gateway modules. It verifies eight application resources, no keys,
dead-letter redrive, work-queue mapping, internal integration references and
token-safe access logs.

The Python verifier captures mocked resource metadata and builds disposable
synthetic state. Each transition retains one root and state lineage while
switching from native addresses to the production modules, including keyed
callers. A separate transition exercises both actual queue-module key moves
and checks legacy key, alias and queue properties against independently frozen
defaults. Creates, destroys, replacements and missing moves fail verification;
policy/tag repairs may remain in-place updates.
The verifier also rejects protected configurable-field changes and unknown
protected values, including partial-response removal and batching-window resets.
Provider-computed identifiers are not treated as caller configuration.

Real-provider planning is refresh-disabled and uses only dummy credentials.
The DynamoDB provider nevertheless performs a plan-time `DescribeTable` read;
a local-only stub accepts that exact fabricated table read and rejects every
other operation. Credential files and alternate workspace/data-directory
settings are excluded. Commands have bounded timeouts and clean up provider
children on timeout or interruption. SIGTERM unwinds the same process-group
cleanup used for timeouts. No real cloud resource, state or backend is accessed.
This is synthetic address-transition evidence, not certification
of any consumer's production plan.

Generate documentation without local lockfile selections so it matches the
clean-checkout build:

```sh
terraform-docs --config ../../../.terraform-docs.yml --lockfile=false .
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.29.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.29.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_apigatewayv2_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_authorizer.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_authorizer) | resource |
| [aws_apigatewayv2_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name) | resource |
| [aws_apigatewayv2_integration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_integration_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration_response) | resource |
| [aws_apigatewayv2_model.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_model) | resource |
| [aws_apigatewayv2_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_route_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route_response) | resource |
| [aws_apigatewayv2_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_apigatewayv2_vpc_link.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_vpc_link) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_api_key_selection_expression"></a> [api\_key\_selection\_expression](#input\_api\_key\_selection\_expression) | WebSocket API key selection expression; preserves the legacy default. | `string` | `"$request.header.x-api-key"` | no |
| <a name="input_api_version"></a> [api\_version](#input\_api\_version) | API version identifier, 1 through 64 characters. | `string` | `null` | no |
| <a name="input_authorizers"></a> [authorizers](#input\_authorizers) | Keyed authorizers. Map keys are physical names; name/provider\_arns/scopes/token\_validation\_expression are deprecated no-op aliases. Canonical TTL falls back to authorizer\_result\_ttl, including zero. | <pre>map(object({<br/>    authorizer_credentials_arn        = optional(string)<br/>    authorizer_type                   = optional(string)<br/>    authorizer_uri                    = optional(string)<br/>    name                              = optional(string)<br/>    token_validation_expression       = optional(string)<br/>    authorizer_payload_format_version = optional(string)<br/>    authorizer_result_ttl             = optional(number)<br/>    authorizer_result_ttl_in_seconds  = optional(number)<br/>    enable_simple_responses           = optional(bool)<br/>    identity_sources                  = optional(list(string))<br/>    provider_arns                     = optional(list(string))<br/>    scopes                            = optional(list(string))<br/>    jwt_configuration = optional(object({<br/>      audience = optional(list(string))<br/>      issuer   = optional(string)<br/>    }))<br/>    timeouts = optional(object({<br/>      delete = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_body"></a> [body](#input\_body) | OpenAPI definition; conflicts with explicit integrations, routes, meaningful CORS and api\_version. | `string` | `null` | no |
| <a name="input_cors_configuration"></a> [cors\_configuration](#input\_cors\_configuration) | HTTP CORS; null, empty, and false/zero-only objects omit the block. | <pre>object({<br/>    allow_credentials = optional(bool, false)<br/>    allow_headers     = optional(list(string))<br/>    allow_methods     = optional(list(string))<br/>    allow_origins     = optional(list(string))<br/>    expose_headers    = optional(list(string))<br/>    max_age           = optional(number, 0)<br/>  })</pre> | `{}` | no |
| <a name="input_credentials_arn"></a> [credentials\_arn](#input\_credentials\_arn) | Quick-create integration credentials ARN. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | API description, at most 1024 characters. | `string` | `null` | no |
| <a name="input_disable_execute_api_endpoint"></a> [disable\_execute\_api\_endpoint](#input\_disable\_execute\_api\_endpoint) | Disable the default execute-api endpoint. | `bool` | `false` | no |
| <a name="input_domain_names"></a> [domain\_names](#input\_domain\_names) | Keyed domain names configurations; null maps mean empty, null entries are rejected. | <pre>map(object({<br/>    domain_name_configuration = object({<br/>      certificate_arn                        = string<br/>      endpoint_type                          = optional(string, "REGIONAL")<br/>      security_policy                        = optional(string, "TLS_1_2")<br/>      ownership_verification_certificate_arn = optional(string)<br/>      ip_address_type                        = optional(string)<br/>    })<br/>    routing_mode = optional(string)<br/>    mutual_tls_authentication = optional(object({<br/>      truststore_uri     = string<br/>      truststore_version = optional(string)<br/>    }))<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      update = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_fail_on_warnings"></a> [fail\_on\_warnings](#input\_fail\_on\_warnings) | Fail OpenAPI imports on warnings. | `bool` | `false` | no |
| <a name="input_integration_responses"></a> [integration\_responses](#input\_integration\_responses) | Keyed integration responses configurations; null maps mean empty, null entries are rejected. | <pre>map(object({<br/>    integration_id                = optional(string)<br/>    integration_key               = optional(string)<br/>    integration_response_key      = string<br/>    content_handling_strategy     = optional(string)<br/>    response_templates            = optional(map(string))<br/>    template_selection_expression = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_integrations"></a> [integrations](#input\_integrations) | Keyed integrations configurations; null maps mean empty, null entries are rejected. | <pre>map(object({<br/>    connection_id                 = optional(string)<br/>    connection_type               = optional(string)<br/>    content_handling_strategy     = optional(string)<br/>    credentials_arn               = optional(string)<br/>    description                   = optional(string)<br/>    integration_method            = optional(string)<br/>    integration_type              = optional(string)<br/>    integration_uri               = optional(string)<br/>    passthrough_behavior          = optional(string)<br/>    integration_subtype           = optional(string)<br/>    payload_format_version        = optional(string)<br/>    template_selection_expression = optional(string)<br/>    vpc_link_key                  = optional(string)<br/>    request_parameters            = optional(map(string))<br/>    request_templates             = optional(map(string))<br/>    timeout_milliseconds          = optional(number)<br/>    response_parameters = optional(map(object({<br/>      mappings    = map(string)<br/>      status_code = string<br/>    })), {})<br/>    tls_config = optional(object({<br/>      server_name_to_verify = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_ip_address_type"></a> [ip\_address\_type](#input\_ip\_address\_type) | API IP address family; null preserves the provider default. | `string` | `null` | no |
| <a name="input_jwt_configuration"></a> [jwt\_configuration](#input\_jwt\_configuration) | Deprecated global JWT fallback; meaningful values apply only to JWT authorizers. | <pre>object({<br/>    audience = optional(list(string))<br/>    issuer   = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_models"></a> [models](#input\_models) | Keyed WebSocket models. Map keys are physical names; required legacy name remains a deprecated no-op alias. | <pre>map(object({<br/>    content_type = string<br/>    name         = string<br/>    schema       = string<br/>    description  = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_mutual_tls_authentication"></a> [mutual\_tls\_authentication](#input\_mutual\_tls\_authentication) | Global mutual TLS fallback for custom domains. | <pre>object({<br/>    truststore_uri     = string<br/>    truststore_version = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Physical API name. | `string` | n/a | yes |
| <a name="input_protocol_type"></a> [protocol\_type](#input\_protocol\_type) | HTTP or WEBSOCKET protocol. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region override for every resource; null uses the provider region. | `string` | `null` | no |
| <a name="input_route_key"></a> [route\_key](#input\_route\_key) | Quick-create HTTP route key. | `string` | `null` | no |
| <a name="input_route_responses"></a> [route\_responses](#input\_route\_responses) | Keyed route responses configurations; null maps mean empty, null entries are rejected. | <pre>map(object({<br/>    route_id                   = optional(string)<br/>    route_key                  = optional(string)<br/>    route_response_key         = string<br/>    response_models            = optional(map(string))<br/>    model_selection_expression = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_route_selection_expression"></a> [route\_selection\_expression](#input\_route\_selection\_expression) | Route selection expression; WebSocket callers typically select $request.body.action. | `string` | `"$request.method $request.path"` | no |
| <a name="input_routes"></a> [routes](#input\_routes) | Keyed routes; route\_key is required. Internal integration\_key and authorizer\_key are alternatives to literal references. request\_parameters is a deprecated boolean-string adapter. | <pre>map(object({<br/>    authorization_type                  = optional(string)<br/>    authorizer_id                       = optional(string)<br/>    model_selection_expression          = optional(string)<br/>    operation_name                      = optional(string)<br/>    route_key                           = optional(string)<br/>    route_response_selection_expression = optional(string)<br/>    target                              = optional(string)<br/>    integration_key                     = optional(string)<br/>    authorizer_key                      = optional(string)<br/>    api_key_required                    = optional(bool)<br/>    authorization_scopes                = optional(list(string))<br/>    request_models                      = optional(map(string))<br/>    request_parameters                  = optional(map(string))<br/>    request_parameter = optional(map(object({<br/>      request_parameter_key = string<br/>      required              = bool<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_stages"></a> [stages](#input\_stages) | Keyed stages. Map keys are physical names; stage\_name is a deprecated no-op alias. Null auto\_deploy retains provider false. | <pre>map(object({<br/>    auto_deploy = optional(bool)<br/>    description = optional(string)<br/>    stage_name  = optional(string)<br/>    access_log_settings = optional(object({<br/>      destination_arn = string<br/>      format          = string<br/>    }))<br/>    default_route_settings = optional(object({<br/>      data_trace_enabled       = optional(bool)<br/>      detailed_metrics_enabled = optional(bool)<br/>      logging_level            = optional(string)<br/>      throttling_burst_limit   = optional(number)<br/>      throttling_rate_limit    = optional(number)<br/>    }))<br/>    route_settings = optional(map(object({<br/>      data_trace_enabled       = optional(bool)<br/>      detailed_metrics_enabled = optional(bool)<br/>      logging_level            = optional(string)<br/>      throttling_burst_limit   = optional(number)<br/>      throttling_rate_limit    = optional(number)<br/>    })), {})<br/>    client_certificate_id = optional(string)<br/>    deployment_id         = optional(string)<br/>    stage_variables       = optional(map(string))<br/>    tags                  = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Shared tags; override generated Name tags. Per-resource tags take final precedence. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_target"></a> [target](#input\_target) | Quick-create integration target; cannot overlap explicit integration, route or stage ownership. | `string` | `null` | no |
| <a name="input_vpc_links"></a> [vpc\_links](#input\_vpc\_links) | Keyed vpc links configurations; null maps mean empty, null entries are rejected. | <pre>map(object({<br/>    security_group_ids = list(string)<br/>    subnet_ids         = list(string)<br/>    tags               = optional(map(string))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_api_endpoint"></a> [api\_endpoint](#output\_api\_endpoint) | The URI of the API |
| <a name="output_api_key_selection_expression"></a> [api\_key\_selection\_expression](#output\_api\_key\_selection\_expression) | The API key selection expression for the API |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the API |
| <a name="output_authorizer_ids"></a> [authorizer\_ids](#output\_authorizer\_ids) | Map of authorizer ids keyed by the original logical resource keys. |
| <a name="output_cors_configuration"></a> [cors\_configuration](#output\_cors\_configuration) | The CORS configuration for the API |
| <a name="output_domain_tags_all"></a> [domain\_tags\_all](#output\_domain\_tags\_all) | Map of domain tags all keyed by the original logical resource keys. |
| <a name="output_domains"></a> [domains](#output\_domains) | Domain identifiers and routing metadata keyed by domain name. |
| <a name="output_execution_arn"></a> [execution\_arn](#output\_execution\_arn) | The ARN prefix to be used in permission policies |
| <a name="output_id"></a> [id](#output\_id) | The API identifier |
| <a name="output_integration_ids"></a> [integration\_ids](#output\_integration\_ids) | Map of integration ids keyed by the original logical resource keys. |
| <a name="output_integration_response_ids"></a> [integration\_response\_ids](#output\_integration\_response\_ids) | Map of integration response ids keyed by the original logical resource keys. |
| <a name="output_integration_response_selection_expressions"></a> [integration\_response\_selection\_expressions](#output\_integration\_response\_selection\_expressions) | Map of integration response selection expressions keyed by the original logical resource keys. |
| <a name="output_model_ids"></a> [model\_ids](#output\_model\_ids) | Map of model ids keyed by the original logical resource keys. |
| <a name="output_route_ids"></a> [route\_ids](#output\_route\_ids) | Map of route ids keyed by the original logical resource keys. |
| <a name="output_route_response_ids"></a> [route\_response\_ids](#output\_route\_response\_ids) | Map of route response ids keyed by the original logical resource keys. |
| <a name="output_stage_arns"></a> [stage\_arns](#output\_stage\_arns) | Map of stage arns keyed by the original logical resource keys. |
| <a name="output_stage_execution_arns"></a> [stage\_execution\_arns](#output\_stage\_execution\_arns) | Map of stage execution arns keyed by the original logical resource keys. |
| <a name="output_stage_ids"></a> [stage\_ids](#output\_stage\_ids) | Map of stage ids keyed by the original logical resource keys. |
| <a name="output_stage_invoke_urls"></a> [stage\_invoke\_urls](#output\_stage\_invoke\_urls) | Map of stage invoke urls keyed by the original logical resource keys. |
| <a name="output_stage_tags_all"></a> [stage\_tags\_all](#output\_stage\_tags\_all) | Map of stage tags all keyed by the original logical resource keys. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | Map of tags assigned to the resource |
| <a name="output_vpc_link_arns"></a> [vpc\_link\_arns](#output\_vpc\_link\_arns) | Map of vpc link arns keyed by the original logical resource keys. |
| <a name="output_vpc_link_ids"></a> [vpc\_link\_ids](#output\_vpc\_link\_ids) | Map of vpc link ids keyed by the original logical resource keys. |
| <a name="output_vpc_link_tags_all"></a> [vpc\_link\_tags\_all](#output\_vpc\_link\_tags\_all) | Map of vpc link tags all keyed by the original logical resource keys. |
<!-- END_TF_DOCS -->
