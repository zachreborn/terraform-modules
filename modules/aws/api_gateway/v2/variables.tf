###########################
# API Configuration
###########################
variable "name" {
  description = "Physical API name."
  type        = string
}

variable "protocol_type" {
  description = "HTTP or WEBSOCKET protocol."
  type        = string
  validation {
    condition     = var.protocol_type == null ? false : contains(["HTTP", "WEBSOCKET"], var.protocol_type)
    error_message = "Protocol must be HTTP or WEBSOCKET."
  }
}

variable "api_key_selection_expression" {
  description = "WebSocket API key selection expression; preserves the legacy default."
  type        = string
  default     = "$request.header.x-api-key"
}

variable "body" {
  description = "OpenAPI definition; conflicts with explicit integrations, routes, meaningful CORS and api_version."
  type        = string
  default     = null
}

variable "credentials_arn" {
  description = "Quick-create integration credentials ARN."
  type        = string
  default     = null
}

variable "description" {
  description = "API description, at most 1024 characters."
  type        = string
  default     = null
  validation {
    condition     = var.description == null ? true : length(var.description) <= 1024
    error_message = "Description must have at most 1024 characters."
  }
}

variable "disable_execute_api_endpoint" {
  description = "Disable the default execute-api endpoint."
  type        = bool
  default     = false
}

variable "fail_on_warnings" {
  description = "Fail OpenAPI imports on warnings."
  type        = bool
  default     = false
}

variable "route_key" {
  description = "Quick-create HTTP route key."
  type        = string
  default     = null
}

variable "route_selection_expression" {
  description = "Route selection expression; WebSocket callers typically select $request.body.action."
  type        = string
  default     = "$request.method $request.path"
}

variable "target" {
  description = "Quick-create integration target; cannot overlap explicit integration, route or stage ownership."
  type        = string
  default     = null
}

variable "api_version" {
  description = "API version identifier, 1 through 64 characters."
  type        = string
  default     = null
  validation {
    condition     = var.api_version == null ? true : length(var.api_version) >= 1 && length(var.api_version) <= 64
    error_message = "API version must have 1 through 64 characters."
  }
}

variable "tags" {
  description = "Shared tags; override generated Name tags. Per-resource tags take final precedence."
  type        = map(string)
  default     = { "terraform" = "true" }
}

variable "region" {
  description = "Region override for every resource; null uses the provider region."
  type        = string
  default     = null
}

variable "ip_address_type" {
  description = "API IP address family; null preserves the provider default."
  type        = string
  default     = null
  validation {
    condition     = var.ip_address_type == null ? true : contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "IP address type must be ipv4 or dualstack."
  }
}

variable "cors_configuration" {
  description = "HTTP CORS; null, empty, and false/zero-only objects omit the block."
  type = object({
    allow_credentials = optional(bool, false)
    allow_headers     = optional(list(string))
    allow_methods     = optional(list(string))
    allow_origins     = optional(list(string))
    expose_headers    = optional(list(string))
    max_age           = optional(number, 0)
  })
  default = {}
}

variable "jwt_configuration" {
  description = "Deprecated global JWT fallback; meaningful values apply only to JWT authorizers."
  type = object({
    audience = optional(list(string))
    issuer   = optional(string)
  })
  default = {}
}

variable "mutual_tls_authentication" {
  description = "Global mutual TLS fallback for custom domains."
  type = object({
    truststore_uri     = string
    truststore_version = optional(string)
  })
  default = null
}

###########################
# Authorizers
###########################
variable "authorizers" {
  description = "Keyed authorizers. Map keys are physical names; name/provider_arns/scopes/token_validation_expression are deprecated no-op aliases. Canonical TTL falls back to authorizer_result_ttl, including zero."
  type = map(object({
    authorizer_credentials_arn        = optional(string)
    authorizer_type                   = optional(string)
    authorizer_uri                    = optional(string)
    name                              = optional(string)
    token_validation_expression       = optional(string)
    authorizer_payload_format_version = optional(string)
    authorizer_result_ttl             = optional(number)
    authorizer_result_ttl_in_seconds  = optional(number)
    enable_simple_responses           = optional(bool)
    identity_sources                  = optional(list(string))
    provider_arns                     = optional(list(string))
    scopes                            = optional(list(string))
    jwt_configuration = optional(object({
      audience = optional(list(string))
      issuer   = optional(string)
    }))
    timeouts = optional(object({
      delete = optional(string)
    }))
  }))
  default = {}
  validation {
    condition     = alltrue([for v in coalesce(var.authorizers, {}) : v != null])
    error_message = "Map entries must be non-null objects; use an empty or null map for no resources."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.authorizers, {}) : v == null ? true : try(contains(["REQUEST", "JWT"], v.authorizer_type), false)])
    error_message = "authorizer_type must be REQUEST, JWT and must be supplied."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.authorizers, {}) : v == null ? true : (v.authorizer_payload_format_version == null ? true : contains(["1.0", "2.0"], v.authorizer_payload_format_version))])
    error_message = "authorizer_payload_format_version must be 1.0, 2.0 when supplied."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.authorizers, {}) : try(v.authorizer_result_ttl == null ? true : v.authorizer_result_ttl >= 0 && v.authorizer_result_ttl <= 3600 && floor(v.authorizer_result_ttl) == v.authorizer_result_ttl, true)])
    error_message = "authorizer_result_ttl must be an integer from 0 through 3600."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.authorizers, {}) : try(v.authorizer_result_ttl_in_seconds == null ? true : v.authorizer_result_ttl_in_seconds >= 0 && v.authorizer_result_ttl_in_seconds <= 3600 && floor(v.authorizer_result_ttl_in_seconds) == v.authorizer_result_ttl_in_seconds, true)])
    error_message = "authorizer_result_ttl_in_seconds must be an integer from 0 through 3600."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.authorizers, {}) : v == null ? true : v.authorizer_result_ttl == null || v.authorizer_result_ttl_in_seconds == null || v.authorizer_result_ttl == v.authorizer_result_ttl_in_seconds])
    error_message = "Legacy and canonical authorizer TTL values must agree when both supplied."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.authorizers, {}) : v == null ? true : v.enable_simple_responses != true || v.authorizer_payload_format_version == "2.0"])
    error_message = "Simple responses require authorizer payload format 2.0."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.authorizers, {}) : v == null ? true : v.authorizer_type != "REQUEST" || v.jwt_configuration == null])
    error_message = "REQUEST authorizers cannot configure nested JWT settings."
  }
}

###########################
# Custom Domain Names
###########################
variable "domain_names" {
  description = "Keyed domain names configurations; null maps mean empty, null entries are rejected."
  type = map(object({
    domain_name_configuration = object({
      certificate_arn                        = string
      endpoint_type                          = optional(string, "REGIONAL")
      security_policy                        = optional(string, "TLS_1_2")
      ownership_verification_certificate_arn = optional(string)
      ip_address_type                        = optional(string)
    })
    routing_mode = optional(string)
    mutual_tls_authentication = optional(object({
      truststore_uri     = string
      truststore_version = optional(string)
    }))
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
    }))
  }))
  default = {}
  validation {
    condition     = alltrue([for v in coalesce(var.domain_names, {}) : v != null])
    error_message = "Map entries must be non-null objects; use an empty or null map for no resources."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.domain_names, {}) : v == null ? true : try(v.domain_name_configuration.endpoint_type == null ? false : contains(["REGIONAL"], v.domain_name_configuration.endpoint_type), false)])
    error_message = "Domain endpoint_type must be REGIONAL."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.domain_names, {}) : v == null ? true : try(v.domain_name_configuration.security_policy == null ? false : contains(["TLS_1_2"], v.domain_name_configuration.security_policy), false)])
    error_message = "Domain security_policy must be TLS_1_2."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.domain_names, {}) : v == null ? true : try(v.domain_name_configuration.ip_address_type == null ? false : contains(["ipv4", "dualstack"], v.domain_name_configuration.ip_address_type), false) || try(v.domain_name_configuration.ip_address_type == null, false)])
    error_message = "Domain ip_address_type must be ipv4, dualstack."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.domain_names, {}) : v == null ? true : (v.routing_mode == null ? true : contains(["API_MAPPING_ONLY", "ROUTING_RULE_ONLY", "ROUTING_RULE_THEN_API_MAPPING"], v.routing_mode))])
    error_message = "routing_mode must be API_MAPPING_ONLY, ROUTING_RULE_ONLY, ROUTING_RULE_THEN_API_MAPPING when supplied."
  }
}

###########################
# Integrations
###########################
variable "integrations" {
  description = "Keyed integrations configurations; null maps mean empty, null entries are rejected."
  type = map(object({
    connection_id                 = optional(string)
    connection_type               = optional(string)
    content_handling_strategy     = optional(string)
    credentials_arn               = optional(string)
    description                   = optional(string)
    integration_method            = optional(string)
    integration_type              = optional(string)
    integration_uri               = optional(string)
    passthrough_behavior          = optional(string)
    integration_subtype           = optional(string)
    payload_format_version        = optional(string)
    template_selection_expression = optional(string)
    vpc_link_key                  = optional(string)
    request_parameters            = optional(map(string))
    request_templates             = optional(map(string))
    timeout_milliseconds          = optional(number)
    response_parameters = optional(map(object({
      mappings    = map(string)
      status_code = string
    })), {})
    tls_config = optional(object({
      server_name_to_verify = optional(string)
    }))
  }))
  default = {}
  validation {
    condition     = alltrue([for v in coalesce(var.integrations, {}) : v != null])
    error_message = "Map entries must be non-null objects; use an empty or null map for no resources."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.integrations, {}) : v == null ? true : try(contains(["AWS", "AWS_PROXY", "HTTP", "HTTP_PROXY", "MOCK"], v.integration_type), false)])
    error_message = "integration_type must be AWS, AWS_PROXY, HTTP, HTTP_PROXY, MOCK and must be supplied."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.integrations, {}) : v == null ? true : (v.connection_type == null ? true : contains(["INTERNET", "VPC_LINK"], v.connection_type))])
    error_message = "connection_type must be INTERNET, VPC_LINK when supplied."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.integrations, {}) : v == null ? true : (v.content_handling_strategy == null ? true : contains(["CONVERT_TO_BINARY", "CONVERT_TO_TEXT"], v.content_handling_strategy))])
    error_message = "content_handling_strategy must be CONVERT_TO_BINARY, CONVERT_TO_TEXT when supplied."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.integrations, {}) : v == null ? true : (v.passthrough_behavior == null ? true : contains(["WHEN_NO_MATCH", "WHEN_NO_TEMPLATES", "NEVER"], v.passthrough_behavior))])
    error_message = "passthrough_behavior must be WHEN_NO_MATCH, WHEN_NO_TEMPLATES, NEVER when supplied."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.integrations, {}) : v == null ? true : (v.payload_format_version == null ? true : contains(["1.0", "2.0"], v.payload_format_version))])
    error_message = "payload_format_version must be 1.0, 2.0 when supplied."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.integrations, {}) : try(v.timeout_milliseconds == null ? true : v.timeout_milliseconds >= 50 && v.timeout_milliseconds <= 30000 && floor(v.timeout_milliseconds) == v.timeout_milliseconds, true)])
    error_message = "Integration timeout must be an integer from 50 through 30000 milliseconds (WebSocket maximum is 29000)."
  }
  validation {
    condition     = alltrue(flatten([for v in coalesce(var.integrations, {}) : v == null ? [] : [for p in v.response_parameters : p == null ? false : can(regex("^[2-5][0-9][0-9]$", p.status_code))]]))
    error_message = "Response parameters require non-null objects with a three-digit status_code from 200 through 599."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.integrations, {}) : v == null ? true : length(distinct([for p in v.response_parameters : p.status_code if p != null])) == length([for p in v.response_parameters : p if p != null])])
    error_message = "Response parameter status codes must be unique within each integration."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.integrations, {}) : v == null ? true : v.integration_subtype == null || v.integration_type == "AWS_PROXY"])
    error_message = "integration_subtype requires integration_type AWS_PROXY."
  }
}

###########################
# Integration Responses
###########################
variable "integration_responses" {
  description = "Keyed integration responses configurations; null maps mean empty, null entries are rejected."
  type = map(object({
    integration_id                = optional(string)
    integration_key               = optional(string)
    integration_response_key      = string
    content_handling_strategy     = optional(string)
    response_templates            = optional(map(string))
    template_selection_expression = optional(string)
  }))
  default = {}
  validation {
    condition     = alltrue([for v in coalesce(var.integration_responses, {}) : v != null])
    error_message = "Map entries must be non-null objects; use an empty or null map for no resources."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.integration_responses, {}) : v == null ? true : (v.content_handling_strategy == null ? true : contains(["CONVERT_TO_BINARY", "CONVERT_TO_TEXT"], v.content_handling_strategy))])
    error_message = "content_handling_strategy must be CONVERT_TO_BINARY, CONVERT_TO_TEXT when supplied."
  }
}

###########################
# Models
###########################
variable "models" {
  description = "Keyed WebSocket models. Map keys are physical names; required legacy name remains a deprecated no-op alias."
  type = map(object({
    content_type = string
    name         = string
    schema       = string
    description  = optional(string)
  }))
  default = {}
  validation {
    condition     = alltrue([for v in coalesce(var.models, {}) : v != null])
    error_message = "Map entries must be non-null objects; use an empty or null map for no resources."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.models, {}) : v == null ? true : can(jsondecode(v.schema))])
    error_message = "Model schema must be valid JSON."
  }
}

###########################
# Routes
###########################
variable "routes" {
  description = "Keyed routes; route_key is required. Internal integration_key and authorizer_key are alternatives to literal references. request_parameters is a deprecated boolean-string adapter."
  type = map(object({
    authorization_type                  = optional(string)
    authorizer_id                       = optional(string)
    model_selection_expression          = optional(string)
    operation_name                      = optional(string)
    route_key                           = optional(string)
    route_response_selection_expression = optional(string)
    target                              = optional(string)
    integration_key                     = optional(string)
    authorizer_key                      = optional(string)
    api_key_required                    = optional(bool)
    authorization_scopes                = optional(list(string))
    request_models                      = optional(map(string))
    request_parameters                  = optional(map(string))
    request_parameter = optional(map(object({
      request_parameter_key = string
      required              = bool
    })), {})
  }))
  default = {}
  validation {
    condition     = alltrue([for v in coalesce(var.routes, {}) : v != null])
    error_message = "Map entries must be non-null objects; use an empty or null map for no resources."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.routes, {}) : v == null ? true : (v.authorization_type == null ? true : contains(["NONE", "AWS_IAM", "CUSTOM", "JWT"], v.authorization_type))])
    error_message = "authorization_type must be NONE, AWS_IAM, CUSTOM, JWT when supplied."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.routes, {}) : v == null ? true : try(length(trimspace(v.route_key)) > 0, false)])
    error_message = "Every route must explicitly supply a nonempty route_key; the logical map key is not a route."
  }
  validation {
    condition     = alltrue(flatten([for v in coalesce(var.routes, {}) : v == null ? [] : [for p in coalesce(v.request_parameters, {}) : p == null ? false : contains(["true", "false"], p)]]))
    error_message = "Deprecated request_parameters values must be exactly true or false strings."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.routes, {}) : v == null ? true : length(v.request_parameter) == 0 || length(coalesce(v.request_parameters, {})) == 0])
    error_message = "Supply singular request_parameter or deprecated plural request_parameters, not both."
  }
  validation {
    condition     = alltrue(flatten([for v in coalesce(var.routes, {}) : v == null ? [] : [for p in v.request_parameter : p != null]]))
    error_message = "request_parameter entries must not be null."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.routes, {}) : v == null ? true : length(distinct([for p in v.request_parameter : p.request_parameter_key if p != null])) == length([for p in v.request_parameter : p if p != null])])
    error_message = "request_parameter_key values must be unique within each route."
  }
}

###########################
# Route Responses
###########################
variable "route_responses" {
  description = "Keyed route responses configurations; null maps mean empty, null entries are rejected."
  type = map(object({
    route_id                   = optional(string)
    route_key                  = optional(string)
    route_response_key         = string
    response_models            = optional(map(string))
    model_selection_expression = optional(string)
  }))
  default = {}
  validation {
    condition     = alltrue([for v in coalesce(var.route_responses, {}) : v != null])
    error_message = "Map entries must be non-null objects; use an empty or null map for no resources."
  }
}

###########################
# Stages
###########################
variable "stages" {
  description = "Keyed stages. Map keys are physical names; stage_name is a deprecated no-op alias. Null auto_deploy retains provider false."
  type = map(object({
    auto_deploy = optional(bool)
    description = optional(string)
    stage_name  = optional(string)
    access_log_settings = optional(object({
      destination_arn = string
      format          = string
    }))
    default_route_settings = optional(object({
      data_trace_enabled       = optional(bool)
      detailed_metrics_enabled = optional(bool)
      logging_level            = optional(string)
      throttling_burst_limit   = optional(number)
      throttling_rate_limit    = optional(number)
    }))
    route_settings = optional(map(object({
      data_trace_enabled       = optional(bool)
      detailed_metrics_enabled = optional(bool)
      logging_level            = optional(string)
      throttling_burst_limit   = optional(number)
      throttling_rate_limit    = optional(number)
    })), {})
    client_certificate_id = optional(string)
    deployment_id         = optional(string)
    stage_variables       = optional(map(string))
    tags                  = optional(map(string))
  }))
  default = {}
  validation {
    condition     = alltrue([for v in coalesce(var.stages, {}) : v != null])
    error_message = "Map entries must be non-null objects; use an empty or null map for no resources."
  }
  validation {
    condition     = alltrue([for s in flatten([for v in coalesce(var.stages, {}) : v == null ? [] : concat(v.default_route_settings == null ? [] : [v.default_route_settings], values(v.route_settings))]) : s != null])
    error_message = "Route settings entries must not be null."
  }
  validation {
    condition     = alltrue([for s in flatten([for v in coalesce(var.stages, {}) : v == null ? [] : concat(v.default_route_settings == null ? [] : [v.default_route_settings], values(v.route_settings))]) : s == null ? true : s.throttling_burst_limit != null && s.throttling_rate_limit != null])
    error_message = "Every default or per-route settings block requires explicit throttling_burst_limit and throttling_rate_limit; zero is allowed but omitted values would be sent as zero by the provider."
  }
  validation {
    condition     = alltrue([for s in flatten([for v in coalesce(var.stages, {}) : v == null ? [] : concat(v.default_route_settings == null ? [] : [v.default_route_settings], values(v.route_settings))]) : s == null ? true : s.logging_level == null ? true : contains(["ERROR", "INFO", "OFF"], s.logging_level)])
    error_message = "Stage logging_level must be ERROR, INFO or OFF."
  }
  validation {
    condition     = alltrue([for s in flatten([for v in coalesce(var.stages, {}) : v == null ? [] : concat(v.default_route_settings == null ? [] : [v.default_route_settings], values(v.route_settings))]) : s == null ? true : s.throttling_burst_limit == null ? true : s.throttling_burst_limit >= 0 && floor(s.throttling_burst_limit) == s.throttling_burst_limit])
    error_message = "Stage throttling_burst_limit must be nonnegative and integral."
  }
  validation {
    condition     = alltrue([for s in flatten([for v in coalesce(var.stages, {}) : v == null ? [] : concat(v.default_route_settings == null ? [] : [v.default_route_settings], values(v.route_settings))]) : s == null ? true : s.throttling_rate_limit == null ? true : s.throttling_rate_limit >= 0])
    error_message = "Stage throttling_rate_limit must be nonnegative."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.stages, {}) : v == null ? true : v.access_log_settings == null ? true : try(length(trimspace(v.access_log_settings.destination_arn)) > 0 && length(trimspace(v.access_log_settings.format)) > 0, false)])
    error_message = "Access logs require both a nonempty destination_arn and format."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.stages, {}) : v == null ? true : v.auto_deploy != true || v.deployment_id == null])
    error_message = "Explicit deployment_id conflicts with auto_deploy=true."
  }
}

###########################
# VPC Links
###########################
variable "vpc_links" {
  description = "Keyed vpc links configurations; null maps mean empty, null entries are rejected."
  type = map(object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
    tags               = optional(map(string))
  }))
  default = {}
  validation {
    condition     = alltrue([for v in coalesce(var.vpc_links, {}) : v != null])
    error_message = "Map entries must be non-null objects; use an empty or null map for no resources."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.vpc_links, {}) : v == null ? true : try(length(v.subnet_ids) > 0, false)])
    error_message = "VPC links require nonempty subnet_ids."
  }
  validation {
    condition     = alltrue([for v in coalesce(var.vpc_links, {}) : v == null ? true : try(length(v.security_group_ids) > 0, false)])
    error_message = "VPC links require nonempty security_group_ids."
  }
}
