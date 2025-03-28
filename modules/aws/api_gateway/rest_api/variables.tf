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

############################################
# API Gateway Resource Variables
############################################

variable "resource_paths" {
  description = "A list of resource paths to create under the API. Each path is a string."
  type        = list(string)
}


############################################
# API Gateway Method Variables
############################################

variable "methods" {
  description = "A map of methods to create for the API. Each key is the HTTP method (e.g., 'GET', 'POST') and the value is a map of method settings."
  type = map(object({
    authorization_scopes = optional(list(string)) #NOTE: Zach
    authorization        = string
    authorizer_id        = optional(string)
    api_key_required     = optional(bool)
    method               = optional(string) #NOTE: Zach
    operation_name       = optional(string) #NOTE: Zach
    resource             = optional(string) #NOTE: Zach
    request_models       = optional(map(string))
    request_parameters   = optional(map(string))
    request_validator_id = optional(string) #NOTE: Zach
    response_models      = optional(map(string))
    response_parameters  = optional(map(string))
  }))
  default = {}
}

variable "method_responses" {
  description = "A map of method responses for the API. Each key is a combination of HTTP method and resource path, and the value is a map of response settings."
  type = map(object({
    status_code         = string
    response_models     = optional(map(string))
    response_parameters = optional(map(string))
    resource            = string
  }))
  default = {}
}

variable "integrations" {
  description = "A map of integrations for the API. Each key is a combination of HTTP method and resource path, and the value is a map of integration settings."
  type = map(object({
    type                    = string
    uri                     = string
    resource                = string
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
  }))
  default = {}
}

variable "vpc_links" {
  description = "A map of VPC links for the API. Each key is the name of the VPC link and the value is a map of VPC link settings."
  type = map(object({
    description = string
    target_arns = list(string)
  }))
  default = {}
}

###############################
# General Variables
###############################

variable "tags" {
  description = "A map of tags to assign to the API."
  type        = map(string)
  default     = {}
}

