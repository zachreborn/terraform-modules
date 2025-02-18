############################################
# API Gateway Variables
############################################
variable "api_key_selection_expression" {
  description = "API key selection expression for the API Gateway"
  type        = string
  default     = "$request.header.x-api-key"
}

variable "body" {
  description = "OpenAPI specification for the API Gateway"
  type        = string
  default     = null
}


variable "cors_configuration" {
  description = "CORS configuration for the API Gateway"
  type = object({
    allow_credentials = optional(bool)         # Whether or not credentials are part of the CORS request.
    allow_headers     = optional(list(string)) # List of allowed HTTP headers.
    allow_methods     = optional(list(string)) # List of allowed methods.
    allow_origins     = optional(list(string)) # List of allowed origins.
    expose_headers    = optional(list(string)) # List of exposed headers in the response.
    max_age           = optional(number)       # Number of seconds for which the browser should cache the preflight response.
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

variable "name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "protocol_type" {
  description = "Protocol type of the API Gateway (HTTP or WEBSOCKET)"
  type        = string
}

variable "route_key" {
  description = "Route key for the API Gateway"
  type        = string
  default     = null
}

variable "route_selection_expression" {
  description = "Route selection expression for the API Gateway"
  type        = string
  default     = "$request.method $request.path"
}

variable "target" {
  description = "Target for the API Gateway"
  type        = string
  default     = null
}

variable "version" {
  description = "Version identifier for the API Gateway. Must be between 1 and 64 characters in length or null."
  type        = string
  default     = null
  validation {
    condition     = var.version == null || (length(var.version) >= 1 && length(var.version) <= 64)
    error_message = "Version identifier must be between 1 and 64 characters in length or null."
  }
}

############################################
# Custom Domain Names
############################################
variable "domain_names" {
  description = "Map of domain names to create for the API Gateway"
  type        = map(object({
    domain_name_configuration = object({
      certificate_arn = string
      endpoint_type   = optional(string, "REGIONAL")
      ownership_verification_certificate_arn = optional(string)
      security_policy = optional(string, "TLS_1_2")
    })
  }))
  default = {}
}


variable "mutual_tls_authentication" {
  description = "Mutual TLS authentication configuration for the API Gateway"
  type = object({
    truststore_uri     = string
    truststore_version = optional(string) # Version of the S3 object that contains the truststore. If not specified, the latest version is used. Versioning must first be enabled on the S3 bucket.
  })
  default = null
}

###############################
# General Variables
###############################
variable "tags" {
  description = "Tags to apply to the resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}
