############################################
# API Gateway Variables
############################################
variable "api_key_source" {
  description = "The source of the API key for metering requests. Valid values are 'HEADER' and 'AUTHORIZER'."
  type        = string
  default     = "HEADER"
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
  description = "The minimum compression size in bytes. Defaults to 0, which disables compression."
  type        = number
  default     = 0
}

variable "name" {
  description = "The name of the API. This is required."
  type        = string
}

variable "fail_on_warnings" {
  description = "Specifies whether to fail on warnings when creating the API. Defaults to true."
  type        = bool
  default     = true
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
  default     = "merge"
}

variable "tags" {
  description = "A map of tags to assign to the API."
  type        = map(string)
  default     = {}
}

