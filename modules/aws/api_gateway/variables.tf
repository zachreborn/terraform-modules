############################################
# API Gateway Variables
############################################
variable "api_key_selection_expression" {
  description = "API key selection expression for the API Gateway"
  type        = string
  default     = "$request.header.x-api-key"
}

variable "body" {
  description = "The OpenAPI specification for the API Gateway. This will conflict with 'cors_configuration', 'integrations', 'routes', and 'version' as the OpenAPI specification would also set these configurations."
  type        = string
  default     = null
}


variable "cors_configuration" {
  description = "CORS configuration for the API Gateway"
  type = object({
    allow_credentials = optional(bool, false)  # Whether or not credentials are part of the CORS request.
    allow_headers     = optional(list(string)) # List of allowed HTTP headers.
    allow_methods     = optional(list(string)) # List of allowed methods.
    allow_origins     = optional(list(string)) # List of allowed origins.
    expose_headers    = optional(list(string)) # List of exposed headers in the response.
    max_age           = optional(number, 0)    # Number of seconds for which the browser should cache the preflight response.
  })
  default = {}
}

variable "credentials_arn" {
  description = "ARN of the credentials for the API Gateway"
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the API Gateway. Must be less than or equal to 1024 characters in length."
  type        = string
  default     = null
  validation {
    condition     = var.description == null || length(var.description) <= 1024
    error_message = "Description must be less than or equal to 1024 characters in length."
  }
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
  description = "Protocol type of the API Gateway. Must be either 'HTTP' or 'WEBSOCKET'."
  type        = string
  validation {
    condition     = contains(["HTTP", "WEBSOCKET"], var.protocol_type)
    error_message = "Protocol type must be either 'HTTP' or 'WEBSOCKET'."
  }
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

variable "api_version" {
  description = "Version identifier for the API Gateway. Must be between 1 and 64 characters in length or null."
  type        = string
  default     = null
  validation {
    condition     = var.version == null || (length(var.version) >= 1 && length(var.version) <= 64)
    error_message = "Version identifier must be between 1 and 64 characters in length or null."
  }
}

############################################
# Authorizers Variables
############################################

variable "authorizers" {
  description = "Map of authorizers to create for the API Gateway"
  type = map(object({
    authorizer_credentials_arn  = optional(string)       # ARN of the credentials to use for the authorizer.
    authorizer_result_ttl       = optional(number)       # TTL in seconds for the authorizer.
    authorizer_type             = optional(string)       # Type of the authorizer. Valid values are "REQUEST" and "JWT".
    authorizer_uri              = optional(string)       # URI of the authorizer.
    identity_sources            = optional(list(string)) # List of identity sources for the authorizer.
    name                        = optional(string)       # Name of the authorizer.
    provider_arns               = optional(list(string)) # List of provider ARNs for the authorizer.
    scopes                      = optional(list(string)) # List of scopes for the authorizer.
    token_validation_expression = optional(string)       # Validation expression for the token.
  }))
  default = {}
}

variable "jwt_configuration" {
  description = "JWT configuration for the API Gateway"
  type = object({
    audience = optional(list(string)) # List of audience values for the JWT configuration.
    issuer   = optional(string)       # Issuer for the JWT configuration.
  })
  default = {}
}

############################################
# Custom Domain Names
############################################
variable "domain_names" {
  description = "Map of domain names to create for the API Gateway"
  type = map(object({
    domain_name_configuration = object({
      certificate_arn                        = string                       # ARN of the ACM certificate to use for the custom domain name.
      endpoint_type                          = optional(string, "REGIONAL") # Endpoint type. Valid values are "REGIONAL".
      ownership_verification_certificate_arn = optional(string)             # ARN of the certificate to use for ownership verification.
      security_policy                        = optional(string, "TLS_1_2")  # TLS version to use for the custom domain name. Valid values are "TLS_1_2".
    })
  }))
  default = {}
}


variable "mutual_tls_authentication" {
  description = "Mutual TLS authentication configuration for the API Gateway"
  type = object({
    truststore_uri     = string           # AWS S3 bucket where the mTLS keys and certificates will be stored.
    truststore_version = optional(string) # Version of the S3 object that contains the truststore. If not specified, the latest version is used. Versioning must first be enabled on the S3 bucket.
  })
  default = null
}

############################################
# Integrations Variables
############################################
variable "integrations" {
  description = "Map of integrations to create for the API Gateway"
  type = map(object({
    connection_id             = optional(string)      # ID of the VPC link for the integration.
    connection_type           = optional(string)      # Type of the VPC link for the integration. Valid values are "VPC_LINK".
    content_handling_strategy = optional(string)      # How to handle request payload content type conversions. Valid values are "CONVERT_TO_BINARY" and "CONVERT_TO_TEXT".
    credentials_arn           = optional(string)      # ARN of the credentials to use for the integration.
    description               = optional(string)      # Description of the integration.
    integration_method        = optional(string)      # HTTP method for the integration.
    integration_type          = optional(string)      # Type of the integration. Valid values are "AWS", "AWS_PROXY", "HTTP", "HTTP_PROXY", "MOCK".
    integration_uri           = optional(string)      # URI of the integration.
    passthrough_behavior      = optional(string)      # How to handle request payload content type conversions. Valid values are "WHEN_NO_MATCH" and "WHEN_NO_TEMPLATES".
    request_parameters        = optional(map(string)) # Map of request parameters for the integration.
    request_templates         = optional(map(string)) # Map of request templates for the integration.
    timeout_milliseconds      = optional(number)      # Timeout in milliseconds for the integration.
  }))
  default = {}
}

############################################
# Integration Responses Variables
############################################

variable "integration_responses" {
  description = "Map of integration responses to create for the API Gateway"
  type = map(object({
    integration_id                = string                # ID of the integration for the integration response.
    integration_response_key      = string                # Key of the integration response.
    content_handling_strategy     = optional(string)      # How to handle request payload content type conversions. Valid values are "CONVERT_TO_BINARY" and "CONVERT_TO_TEXT".
    response_templates            = optional(map(string)) # Map of response templates for the integration response.
    template_selection_expression = optional(string)      # Expression to select the template for the integration response.
  }))
  default = {}
}

############################################ 
# Models Variables
############################################

variable "models" {
  description = "Map of models to create for the API Gateway"
  type = map(object({
    content_type = string           # Content type of the model.
    description  = optional(string) # Description of the model.
    name         = string           # Name of the model.
    schema       = string           # Schema of the model.
  }))
  default = {}
}



############################################
# Routes Variables
############################################
variable "routes" {
  description = "Map of routes to create for the API Gateway"
  type = map(object({
    api_key_required                    = optional(bool)         # Whether an API key is required for the route.
    authorization_scopes                = optional(list(string)) # List of authorization scopes for the route.
    authorization_type                  = optional(string)       # Type of authorization for the route. Valid values are "NONE", "AWS_IAM", "CUSTOM", "JWT".
    authorizer_id                       = optional(string)       # ID of the authorizer to use for the route.
    model_selection_expression          = optional(string)       # Expression to select the model for the route.
    operation_name                      = optional(string)       # Operation name for the route.
    request_models                      = optional(map(string))  # Map of request models for the route.
    request_parameters                  = optional(map(string))  # Map of request parameters for the route.
    route_key                           = optional(string)       # Route key for the route.
    route_response_selection_expression = optional(string)       # Expression to select the route response for the route.
    target                              = optional(string)       # Target for the route.
  }))
  default = {}
}

############################################
# Route Responses Variables
############################################

variable "route_responses" {
  description = "Map of route responses to create for the API Gateway"
  type = map(object({
    route_id                   = string                # ID of the route for the route response.
    route_response_key         = string                # Key of the route response.
    response_models            = optional(map(string)) # Map of response models for the route response.
    model_selection_expression = optional(string)      # Expression to select the template for the route response.
  }))
  default = {}
}

############################################
# Stages Variables
############################################
variable "stages" {
  description = "Map of stages to create for the API Gateway"
  type = map(object({
    auto_deploy = optional(bool)   # Whether to automatically deploy the stage.
    description = optional(string) # Description of the stage.
    stage_name  = optional(string) # Name of the stage.
  }))
  default = {}
}

############################################
# VPC Links Variables
############################################

variable "vpc_links" {
  description = "Map of VPC links to create for the API Gateway"
  type = map(object({
    security_group_ids = list(string)          # List of security group IDs for the VPC link.
    subnet_ids         = list(string)          # List of subnet IDs for the VPC link.
    tags               = optional(map(string)) # Map of tags to apply to the VPC link.
  }))
  default = {}
  # Example: 
  # vpc_links = {
  #   my_vpc_link_name = {
  #     security_group_ids = ["sg-12345678"]
  #     subnet_ids         = ["subnet-12345678"]
  #   },
  #   link_2_name = {
  #     security_group_ids = ["sg-87654321"]
  #     subnet_ids         = ["subnet-87654321"]
  #   }
  # }
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
