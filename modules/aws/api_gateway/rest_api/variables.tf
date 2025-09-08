############################################
# API Gateway Variables
############################################
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
  description = "The minimum compression size in bytes. Must be either a string containing an integer between -1 and 10485760 or set to null. Defaults to null, which disables compression."
  type        = number
  default     = null
  validation {
    condition     = var.minimum_compression_size == null || can(var.minimum_compression_size >= -1 && var.minimum_compression_size <= 10485760)
    error_message = "minimum_compression_size must null or an integer be between -1 and 10485760."
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

variable "stage_name" {
  description = "(Required) Name of the stage"
  type        = string
  validation {
    condition     = length(var.stage_name) > 0
    error_message = "stage_name must be a non-empty string."
  }
}

############################################
# API Gateway Resource Variables
############################################

variable "resources" {
  description = "A map of resources to create under the API. Each key is the resource path and the value is a map of resource settings."
  type = map(object({
    path_part = string
  }))
  default = {}
}

############################################
# API Gateway Method Variables
############################################

variable "methods" {
  description = "A map of methods to create for the API. Each key is the HTTP method (e.g., 'GET', 'POST') and the value is a map of method settings."
  type = map(object({
    resource             = string # The resource key this method belongs to
    authorization_scopes = optional(list(string))
    authorization        = string
    authorizer_id        = optional(string)
    api_key_required     = optional(bool)
    http_method          = string
    operation_name       = optional(string)
    request_models       = optional(map(string))
    request_parameters   = optional(map(string))
    request_validator_id = optional(string)
    response_models      = optional(map(string))
    response_parameters  = optional(map(string))
  }))
  default = {}
}

variable "method_responses" {
  description = "A map of method responses for the API. Each key is a combination of HTTP method and resource path, and the value is a map of response settings."
  type = map(object({
    resource            = string # The resource key this method response belongs to
    method              = string # The method key this response belongs to
    status_code         = string
    response_models     = optional(map(string))
    response_parameters = optional(map(string))
  }))
  default = {}
}

variable "integrations" {
  description = "A map of integrations for the API. Each key is a combination of HTTP method and resource path, and the value is a map of integration settings."
  type = map(object({
    type                    = string
    uri                     = string
    resource                = string
    method                  = string # The method key this integration belongs to
    credentials             = optional(string)
    http_method             = optional(string)
    integration_http_method = optional(string)
    request_parameters      = optional(map(string))
    request_templates       = optional(map(string))
    passthrough_behavior    = optional(string)
    content_handling        = optional(string)
    timeout_milliseconds    = optional(number)
    cache_key_parameters    = optional(list(string))
    cache_namespace         = optional(string)
    connection_type         = optional(string)
    connection_id           = optional(string)
    vpc_link_key            = optional(string) # The VPC Link key from vpc_links variable when using VPC_LINK
  }))
  default = {}
}

############################################
# VPC Link Variables
############################################

variable "vpc_links" {
  description = "A map of VPC links for the API. Each key is the name of the VPC link and the value is a map of VPC link settings."
  type = map(object({
    description = string
    target_arns = list(string)
  }))
  default = {}
}

###############################
# Domain Name and mTLS Variables
###############################

variable "enable_mtls" {
  description = "Enable mTLS configuration for the API Gateway"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Custom domain name for the API Gateway. Required for mTLS."
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the custom domain. Required for custom domain."
  type        = string
  default     = null
}

variable "mtls_config" {
  description = "mTLS configuration for the custom domain."
  type = object({
    truststore_uri     = string           # S3 URI to the truststore file
    truststore_version = optional(string) # Version of the truststore
  })
  default = null
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

###############################
# General Variables
###############################

variable "tags" {
  description = "A map of tags to assign to the API."
  type        = map(string)
  default     = {}
}

##############################
# S3 Bucket Variables
##############################

variable "bucket_name" {
  description = "Name of the S3 bucket for mTLS truststore. Required when enable_mtls is true and domain_name is provided. Must be lowercase and less than or equal to 63 characters in length."
  type        = string
  default     = null
  validation {
    condition = var.bucket_name == null || (
      length(var.bucket_name) > 0 &&
      length(var.bucket_name) <= 63 &&
      can(regex("^[a-z0-9.-]+$", var.bucket_name)) &&
      !can(regex("^[.-]", var.bucket_name)) &&
      !can(regex("[.-]$", var.bucket_name))
    )
    error_message = "bucket_name must be lowercase, 1-63 characters, contain only letters, numbers, dots, and hyphens, and not start or end with dots or hyphens."
  }
}
