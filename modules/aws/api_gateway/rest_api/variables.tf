###########################
# API Gateway Variables
###########################
variable "api_key_source" {
  description = "The source of the API key for metering requests. Valid values are 'HEADER' and 'AUTHORIZER'."
  type        = string
  default     = "HEADER"
  validation {
    condition     = var.api_key_source == null || contains(["HEADER", "AUTHORIZER"], var.api_key_source)
    error_message = "api_key_source must be either 'HEADER', 'AUTHORIZER', or null."
  }
}

variable "binary_media_types" {
  description = "A list of binary media types supported by the Rest API."
  type        = list(string)
  default     = []
}

variable "body" {
  description = "The body of the API definition in JSON format."
  type        = string
  default     = null
}

variable "description" {
  description = "A description of the API."
  type        = string
  default     = null
}

variable "disable_execute_api_endpoint" {
  description = "Specifies whether the execute API endpoint is disabled. Defaults to false."
  type        = bool
  default     = false
}

variable "endpoint_configuration" {
  description = "The endpoint configuration for the API. This is a complex object."
  type = object({
    types            = list(string)           # List of endpoint types. Valid values are 'EDGE', 'REGIONAL', and 'PRIVATE'.
    vpc_endpoint_ids = optional(list(string)) # List of VPC endpoint IDs for private endpoints. Only supported if the type is 'PRIVATE'.
  })
  default = null
}

variable "minimum_compression_size" {
  description = "The minimum compression size in bytes. Must be either an integer between -1 and 10485760 or set to null. Defaults to null, which disables compression."
  type        = number
  default     = null
  validation {
    condition     = var.minimum_compression_size == null || (var.minimum_compression_size >= -1 && var.minimum_compression_size <= 10485760)
    error_message = "minimum_compression_size must be null or an integer between -1 and 10485760."
  }
}

variable "name" {
  description = "The name of the API. This is required."
  type        = string
}

variable "fail_on_warnings" {
  description = "Specifies whether to fail on warnings when creating the API. Defaults to false."
  type        = bool
  default     = false
}

variable "parameters" {
  description = "A map of API Gateway-specific parameters that can be used to configure the API."
  type        = map(string)
  default     = {}
}

variable "policy" {
  description = "The resource policy for the API in JSON format."
  type        = string
  default     = null
}

variable "put_rest_api_mode" {
  description = "The mode for the PUT Rest API operation. Valid values are 'merge' and 'overwrite'."
  type        = string
  default     = "overwrite"
  validation {
    condition     = contains(["merge", "overwrite"], var.put_rest_api_mode)
    error_message = "put_rest_api_mode must be either 'merge' or 'overwrite'."
  }
}

###########################
# Resource Variables
###########################
variable "resources" {
  description = "A map of resources to create under the API. Each key is the resource path and the value is a map of resource settings."
  type = map(object({
    path_part = string
  }))
  default = {}
}

###########################
# Model Variables
###########################
variable "models" {
  description = "A map of models for the API. Each key is the model name."
  type = map(object({
    content_type = string
    description  = optional(string)
    schema       = string # JSON schema as a string
  }))
  default = {}
}

###########################
# Request Validator Variables
###########################
variable "request_validators" {
  description = "A map of request validators for the API."
  type = map(object({
    validate_request_body       = bool
    validate_request_parameters = bool
    name                        = optional(string) # Defaults to map key if not provided
  }))
  default = {}
}

###########################
# Authorizer Variables
###########################
variable "authorizers" {
  description = "A map of authorizers for the API."
  type = map(object({
    type                             = string                 # TOKEN, REQUEST, or COGNITO_USER_POOLS
    authorizer_uri                   = optional(string)       # Required for Lambda authorizers
    authorizer_credentials           = optional(string)       # IAM role ARN for invoking authorizer
    identity_source                  = optional(string)       # Source of the identity in the request
    identity_validation_expression   = optional(string)       # Regex for validating identity source
    authorizer_result_ttl_in_seconds = optional(number, 300)  # TTL for cached authorizer results (0-3600)
    provider_arns                    = optional(list(string)) # Required for COGNITO_USER_POOLS
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.authorizers :
      contains(["TOKEN", "REQUEST", "COGNITO_USER_POOLS"], v.type)
    ])
    error_message = "Authorizer type must be one of: TOKEN, REQUEST, COGNITO_USER_POOLS."
  }
}

###########################
# Method Variables
###########################
variable "methods" {
  description = "A map of methods to create for the API. Each key is a unique identifier for the method."
  type = map(object({
    resource             = string # The resource key this method belongs to
    http_method          = string
    authorization        = string
    authorizer_id        = optional(string) # Can be authorizer key or ARN
    authorization_scopes = optional(list(string))
    api_key_required     = optional(bool, false)
    operation_name       = optional(string)
    request_models       = optional(map(string))
    request_parameters   = optional(map(string))
    request_validator_id = optional(string) # Can be validator key or ID
  }))
  default = {}
}

###########################
# Method Response Variables
###########################
variable "method_responses" {
  description = "A map of method responses for the API."
  type = map(object({
    resource            = string # The resource key this method response belongs to
    method              = string # The method key this response belongs to
    status_code         = string
    response_models     = optional(map(string))
    response_parameters = optional(map(string))
  }))
  default = {}
}

###########################
# Integration Variables
###########################
variable "integrations" {
  description = "A map of integrations for the API."
  type = map(object({
    type                    = string
    uri                     = string
    resource                = string # The resource key
    method                  = string # The method key
    integration_http_method = optional(string)
    credentials             = optional(string)
    connection_type         = optional(string)
    connection_id           = optional(string)
    vpc_link_key            = optional(string) # The VPC Link key from vpc_links variable
    request_parameters      = optional(map(string))
    request_templates       = optional(map(string))
    passthrough_behavior    = optional(string)
    content_handling        = optional(string)
    timeout_milliseconds    = optional(number, 29000)
    cache_key_parameters    = optional(list(string))
    cache_namespace         = optional(string)
  }))
  default = {}
}

###########################
# Integration Response Variables
###########################
variable "integration_responses" {
  description = "A map of integration responses for the API."
  type = map(object({
    resource            = string # The resource key
    method              = string # The method key
    status_code         = string
    selection_pattern   = optional(string)
    response_parameters = optional(map(string))
    response_templates  = optional(map(string))
    content_handling    = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.integration_responses :
      v.content_handling == null || contains(["CONVERT_TO_BINARY", "CONVERT_TO_TEXT"], v.content_handling)
    ])
    error_message = "content_handling must be null, 'CONVERT_TO_BINARY', or 'CONVERT_TO_TEXT'."
  }
}

###########################
# Gateway Response Variables
###########################
variable "gateway_responses" {
  description = "A map of gateway responses for the API."
  type = map(object({
    response_type       = string
    status_code         = optional(string)
    response_parameters = optional(map(string))
    response_templates  = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.gateway_responses :
      contains([
        "DEFAULT_4XX", "DEFAULT_5XX", "RESOURCE_NOT_FOUND", "UNAUTHORIZED",
        "INVALID_API_KEY", "ACCESS_DENIED", "AUTHORIZER_FAILURE", "AUTHORIZER_CONFIGURATION_ERROR",
        "INVALID_SIGNATURE", "EXPIRED_TOKEN", "MISSING_AUTHENTICATION_TOKEN", "INTEGRATION_FAILURE",
        "INTEGRATION_TIMEOUT", "API_CONFIGURATION_ERROR", "UNSUPPORTED_MEDIA_TYPE", "BAD_REQUEST_PARAMETERS",
        "BAD_REQUEST_BODY", "REQUEST_TOO_LARGE", "THROTTLED", "QUOTA_EXCEEDED"
      ], v.response_type)
    ])
    error_message = "response_type must be a valid API Gateway response type."
  }
}

###########################
# VPC Link Variables
###########################
variable "vpc_links" {
  description = "A map of VPC links for the API. Each key is the name of the VPC link."
  type = map(object({
    description = string
    target_arns = list(string)
  }))
  default = {}
}

###########################
# Stage Variables
###########################
variable "stage_name" {
  description = "Name of the stage"
  type        = string
  validation {
    condition     = length(var.stage_name) > 0
    error_message = "stage_name must be a non-empty string."
  }
}

variable "stage_description" {
  description = "Description of the stage"
  type        = string
  default     = null
}

variable "stage_variables" {
  description = "A map of stage variables"
  type        = map(string)
  default     = {}
}

variable "cache_cluster_enabled" {
  description = "Specifies whether a cache cluster is enabled for the stage"
  type        = bool
  default     = false
}

variable "cache_cluster_size" {
  description = "The size of the cache cluster for the stage, if enabled. Valid values are 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237"
  type        = string
  default     = "0.5"
  validation {
    condition = contains([
      "0.5", "1.6", "6.1", "13.5", "28.4", "58.2", "118", "237"
    ], var.cache_cluster_size)
    error_message = "cache_cluster_size must be one of: 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237"
  }
}

variable "client_certificate_id" {
  description = "The identifier of a client certificate for the stage"
  type        = string
  default     = null
}

variable "documentation_version" {
  description = "The version of the associated API documentation"
  type        = string
  default     = null
}

variable "xray_tracing_enabled" {
  description = "Whether active tracing with X-ray is enabled"
  type        = bool
  default     = false
}

variable "access_log_settings" {
  description = "Access log settings for the stage"
  type = object({
    destination_arn = string # ARN of CloudWatch Logs log group or Kinesis Data Firehose delivery stream
    format          = string # Log format
  })
  default = null
}

variable "stage_throttle_settings" {
  description = "Stage-level throttle settings"
  type = object({
    burst_limit = number
    rate_limit  = number
  })
  default = null
}

###########################
# Method Settings Variables
###########################
variable "method_settings" {
  description = "A map of method settings for specific resource/method paths"
  type = map(object({
    method_path                                = string
    metrics_enabled                            = optional(bool, false)
    logging_level                              = optional(string, "OFF")
    data_trace_enabled                         = optional(bool, false)
    throttling_burst_limit                     = optional(number, -1)
    throttling_rate_limit                      = optional(number, -1)
    caching_enabled                            = optional(bool, false)
    cache_ttl_in_seconds                       = optional(number, 300)
    cache_data_encrypted                       = optional(bool, false)
    require_authorization_for_cache_control    = optional(bool, false)
    unauthorized_cache_control_header_strategy = optional(string, "SUCCEED_WITH_RESPONSE_HEADER")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.method_settings :
      contains(["OFF", "ERROR", "INFO"], v.logging_level)
    ])
    error_message = "logging_level must be one of: OFF, ERROR, INFO"
  }

  validation {
    condition = alltrue([
      for k, v in var.method_settings :
      contains(["FAIL_WITH_403", "SUCCEED_WITH_RESPONSE_HEADER", "SUCCEED_WITHOUT_RESPONSE_HEADER"], v.unauthorized_cache_control_header_strategy)
    ])
    error_message = "unauthorized_cache_control_header_strategy must be one of: FAIL_WITH_403, SUCCEED_WITH_RESPONSE_HEADER, SUCCEED_WITHOUT_RESPONSE_HEADER"
  }
}

###########################
# Usage Plan Variables
###########################
variable "usage_plans" {
  description = "A map of usage plans for the API"
  type = map(object({
    name        = string
    description = optional(string)
    api_stages = list(object({
      stage_name = string
    }))
    quota_settings = optional(object({
      limit  = number
      offset = optional(number, 0)
      period = string # DAY, WEEK, or MONTH
    }))
    throttle_settings = optional(object({
      burst_limit = number
      rate_limit  = number
    }))
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for k, v in var.usage_plans : [
        for qs in(v.quota_settings != null ? [v.quota_settings] : []) :
        contains(["DAY", "WEEK", "MONTH"], qs.period)
      ]
    ]))
    error_message = "quota_settings period must be one of: DAY, WEEK, MONTH"
  }
}

###########################
# API Key Variables
###########################
variable "api_keys" {
  description = "A map of API keys"
  type = map(object({
    name        = string
    description = optional(string)
    enabled     = optional(bool, true)
    value       = optional(string) # Custom key value, generated if not provided
  }))
  default = {}
}

###########################
# Usage Plan Key Association Variables
###########################
variable "usage_plan_keys" {
  description = "A map of usage plan key associations"
  type = map(object({
    usage_plan_key = string # Key from usage_plans
    api_key_key    = string # Key from api_keys
  }))
  default = {}
}

###########################
# Domain Name and mTLS Variables
###########################
variable "domain_name" {
  description = "Custom domain name for the API Gateway. Required for mTLS."
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the custom domain. Must be created separately using the acm_certificate module."
  type        = string
  default     = null
}

variable "enable_mtls" {
  description = "Enable mTLS configuration for the API Gateway"
  type        = bool
  default     = false
}

variable "mtls_config" {
  description = "mTLS configuration for the custom domain. S3 bucket and truststore must be created separately."
  type = object({
    truststore_uri     = string           # S3 URI to the truststore file (e.g., s3://bucket-name/path/to/truststore.pem)
    truststore_version = optional(string) # Version of the truststore file (use S3 object version_id)
  })
  default = null
}

variable "bucket_name" {
  description = "Name of the S3 bucket for mTLS truststore. This is a reference only - the bucket must be created separately using the s3 module."
  type        = string
  default     = null
  validation {
    condition     = var.bucket_name == null || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be a valid S3 bucket name (lowercase, 3-63 characters, alphanumeric and hyphens only)."
  }
}

variable "security_policy" {
  description = "Security policy for the custom domain. Valid values: TLS_1_0, TLS_1_2"
  type        = string
  default     = "TLS_1_2"
  validation {
    condition     = contains(["TLS_1_0", "TLS_1_2"], var.security_policy)
    error_message = "Security policy must be either TLS_1_0 or TLS_1_2."
  }
}

variable "endpoint_configuration_types" {
  description = "List of endpoint types for the custom domain. Valid values: EDGE, REGIONAL, PRIVATE"
  type        = list(string)
  default     = ["REGIONAL"]
  validation {
    condition     = alltrue([for t in var.endpoint_configuration_types : contains(["EDGE", "REGIONAL", "PRIVATE"], t)])
    error_message = "All endpoint configuration types must be one of: EDGE, REGIONAL, PRIVATE."
  }
}

variable "base_path" {
  description = "Base path mapping for the custom domain"
  type        = string
  default     = null
}

###########################
# General Variables
###########################
variable "tags" {
  description = "A map of tags to assign to the API."
  type        = map(string)
  default     = {}
}
