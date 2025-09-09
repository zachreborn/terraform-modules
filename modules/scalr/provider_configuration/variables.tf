###########################
# Scalr Provider Variables
###########################

variable "scalr_environments" {
    description = "List of Scalr Environments which the provider will be shared to."
    type        = list(string)
    default     = null
}

variable "scalr_hostname" {
    description = "The Scalr hostname."
    type        = string
}

variable "scalr_provider_name" {
    description = "Name of the Scalr Provider Configuration."
    type        = string
    default     = "scalr"
}

variable "scalr_owners" {
    description = "List of Scalr User IDs who will own the Provider Configuration."
    type        = list(string)
    default     = []
}

variable "scalr_token" {
    description = "The Scalr API token."
    type        = string
    sensitive   = true
}

###########################
# AWS Provider Variables
###########################

variable "aws_access_key" {
    description = "The AWS access key."
    type        = string
    sensitive   = true
    default     = null
}

variable "aws_account_type" {
    description = "The type of AWS account. Valid values are 'regular', 'gov-cloud', and 'cn-cloud'."
    type        = string
    default     = "regular"
    validation {
        condition     = contains(["regular", "gov-cloud", "cn-cloud"], var.aws_account_type)
        error_message = "The aws_account_type must be one of 'regular', 'gov-cloud', or 'cn-cloud'."
    }
}

variable "aws_audience" {
    description = "The audience for the AWS credentials. Required if credentials_type is set to 'oidc'."
    type        = string
    default     = null
}

variable "aws_credentials_type" {
    description = "The type of AWS credentials. Valid values are 'access_keys', 'oidc', and 'role_delegation'."
    type        = string
    default = "oidc"
    validation {
        condition     = contains(["access_keys", "oidc", "role_delegation"], var.aws_credentials_type)
        error_message = "The aws_credentials_type must be one of 'access_keys', 'oidc', or 'role_delegation'."
    }
}

variable "aws_environments" {
    description = "List of Scalr Environments which the provider will be shared to."
    type        = list(string)
    default     = null
}

variable "aws_external_id" {
    description = "The external ID to use when assuming the role. Required if aws_credentials_type is set to 'role_delegation' and the role requires an external ID."
    type        = string
    default     = null
}

variable "aws_export_shell_variables" {
    description = "Whether to export AWS credentials as shell variables when using the Scalr CLI."
    type        = bool
    default     = false
}

variable "aws_provider_name" {
    description = "Name of the AWS Provider Configuration."
    type        = string
    default     = "aws"
}

variable "aws_owners" {
    description = "List of Scalr User IDs who will own the Provider Configuration."
    type        = list(string)
    default     = null
}

variable "aws_role_arn" {
    description = "The ARN of the role to assume. Required if aws_credentials_type is set to 'oidc' or 'role_delegation'."
    type        = string
    default     = null
}

variable "aws_secret_key" {
    description = "The AWS secret key."
    type        = string
    sensitive   = true
    default     = null
}

variable "aws_trusted_entity_type" {
    description = "The type of trusted entity for the role. Valid values are 'aws_account' and 'aws_service'."
    type        = string
    default     = "aws_account"
    validation {
        condition     = contains(["aws_account", "aws_service"], var.aws_trusted_entity_type)
        error_message = "The aws_trusted_entity_type must be one of 'aws_account' or 'aws_service'."
    }
}

###########################
# Environment Variables
###########################
variable "environments" {
    description = "Map of Environments."
    type = map(object({
        default_provider_configurations = optional(map(string)),
        name                            = string,
        remote_backend                  = optional(string),
        remote_backend_overridable      = optional(bool),
        storage_profile_id              = optional(string),
        tag_ids                         = optional(list(string))
    }))
}


###########################
# General Variables
###########################

