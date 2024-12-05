############################################
# Required
############################################

variable "name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "protocol_type" {
  description = "Protocol type of the API Gateway (HTTP or WEBSOCKET)"
  type        = string
}

############################################
# Optional
############################################

variable "api_key_selection_expression" {
  description = "API key selection expression for the API Gateway"
  type        = string
  default     = "$request.header.x-api-key"
}

variable "cors_configuration" {
  description = "CORS configuration for the API Gateway"
  type = object({
    allow_credentials = bool
    allow_headers     = list(string)
    allow_methods     = list(string)
    allow_origins     = list(string)
    expose_headers    = list(string)
    max_age           = number
  })
  default = {
    allow_credentials = false
    allow_headers     = []
    allow_methods     = []
    allow_origins     = []
    expose_headers    = []
    max_age           = 0
  }
}

variable "credentials_arn" {
  description = "ARN of the credentials for the API Gateway"
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = null
}

variable "disable_execute_api_endpoint" {
  description = "Whether to disable the execute-api endpoint"
  type        = bool
  default     = false
}

variable "fail_on_warnings" {
  description = "Whether to fail on warnings during API Gateway creation"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the API Gateway"
  type        = map(string)
  default     = {}
}

variable "target" {
  description = "Target for the API Gateway"
  type        = string
  default     = null
}

variable "api_gateway_version" {
  description = "Version of the API Gateway"
  type        = string
  default     = null
}

variable "body" {
  description = "OpenAPI specification for the API Gateway"
  type        = string
  default     = null
}
