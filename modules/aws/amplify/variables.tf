###########################
# Resource Variables
###########################

###########################
# Amplify App
###########################

variable "access_token" {
  description = "Access token for the Amplify App."
  type        = string
  default     = null
}

variable "auto_branch_creation_config" {
  description = "Auto branch creation config for the Amplify App."
  type = map(object({
    basic_auth_credentials        = optional(string)
    build_spec                    = optional(string)
    enable_auto_build             = optional(bool)
    enable_basic_auth             = optional(bool)
    enable_performance_mode       = optional(bool)
    enable_pull_request_preview   = optional(bool)
    environment_variables         = optional(map(string))
    framework                     = optional(string)
    pull_request_environment_name = optional(string)
    stage                         = optional(string) # Description of the stage. Valid values are PRODUCTION, BETA, DEVELOPMENT, EXPERIMENTAL, PULL_REQUEST.
  }))
  default = null
}

variable "auto_branch_creation_patterns" {
  description = "Patterns for auto branch creation."
  type        = list(string)
  default     = null
}

variable "basic_auth_credentials" {
  description = "Basic auth credentials for the Amplify App."
  type        = string
  default     = null
}

variable "build_spec" {
  description = "Build spec for the Amplify App."
  type        = string
  default     = null
}

variable "cache_config_type" {
  description = "Cache config type for the Amplify App. Valid values are AMPLIFY_MANAGED, AMPLIFY_MANAGED_NO_COOKIES, "
  type        = string
  default     = "AMPLIFY_MANAGED"
  validation {
    condition     = var.cache_config_type == "AMPLIFY_MANAGED" || var.cache_config_type == "AMPLIFY_MANAGED_NO_COOKIES"
    error_message = "Cache config type must be either AMPLIFY_MANAGED or AMPLIFY_MANAGED_NO_COOKIES."
  }
}

variable "custom_headers" {
  description = "Custom headers in a map for the Amplify App."
  type        = map(string)
  default     = null
}

variable "custom_rules" {
  description = "Custom rules for the Amplify App."
  type = map(object({
    condition = optional(string) # Condition for a URL redirect or rewrite.
    source    = string           # Source pattern for URL redirect or rewrite.
    status    = optional(string) # Status code for URL redirect or rewrite. Valid values are 200, 301, 302, 404, 404-200.
    target    = string           # Target pattern for URL redirect or rewrite.
  }))
}

variable "description" {
  description = "Description of the Amplify App."
  type        = string
  default     = null
}

variable "enable_auto_branch_creation" {
  description = "Enable auto branch creation for the Amplify App."
  type        = bool
  default     = false
}

variable "enable_basic_auth" {
  description = "Enable basic auth for the Amplify App."
  type        = bool
  default     = false
}

variable "enable_branch_auto_build" {
  description = "Enable branch auto build for the Amplify App."
  type        = bool
  default     = false
}

variable "enable_branch_auto_deletion" {
  description = "Enable branch auto deletion for the Amplify App."
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Environment variables in a map for the Amplify App."
  type        = map(string)
  default     = null
}

variable "name" {
  description = "Name of the Amplify App."
  type        = string
}

variable "iam_service_role_arn" {
  description = "IAM service role ARN for the Amplify App."
  type        = string
  default     = null
}

variable "oauth_token" {
  description = "OAuth token for the Amplify App."
  type        = string
  default     = null
}

variable "platform" {
  description = "Platform for the Amplify App. Options are WEB or WEB_COMPUTE."
  type        = string
  default     = "WEB"
  validation {
    condition     = var.platform == "WEB" || var.platform == "WEB_COMPUTE"
    error_message = "Platform must be either WEB or WEB_COMPUTE."
  }
}

variable "repository" {
  description = "Repository for the Amplify App. This could be hosted in AWS Code Commit, Bitbucket, GitHub, GitLab, etc."
  type        = string
  default     = null
}

###########################
# Amplify Branch
###########################

variable "branches" {
  description = "Branches for the Amplify App."
  type = map(object({
    basic_auth_credentials        = optional(string)      # Basic auth credentials for the branch.
    branch_name                   = string                # The name of the branch.
    description                   = optional(string)      # The description of the branch.
    display_name                  = optional(string)      # The display name of the branch. This gets used as the default domain prefix.
    enable_auto_build             = optional(bool, true)  # Enable auto build for the branch.
    enable_basic_auth             = optional(bool)        # Enable basic auth for the branch.
    enable_notification           = optional(bool)        # Enable notification for the branch.
    enable_performance_mode       = optional(bool)        # Enable performance mode for the branch.
    enable_pull_request_preview   = optional(bool)        # Enable pull request preview for the branch.
    environment_variables         = optional(map(string)) # Map of environment variables for the branch.
    framework                     = optional(string)      # The framework for the branch.
    pull_request_environment_name = optional(string)      # The name of the pull request environment.
    stage                         = optional(string)      # The stage for the branch. Valid values are PRODUCTION, BETA, DEVELOPMENT, EXPERIMENTAL, PULL_REQUEST.
    ttl                           = optional(number)      # The TTL for the branch.
  }))
}

###########################
# Amplify Domain Association
###########################

variable "domains" {
  description = "Domains for the Amplify App."
  type = map(object({
    enable_certificate     = optional(bool, true)  # Enable certificate for the domain association.
    certificate_type       = optional(string)      # The certificate type for the domain association. Valid values are AMPLIFY_MANAGED or CUSTOM.
    custom_certificate_arn = optional(string)      # The ARN for the custom certificate.
    domain_name            = string                # The domain name for the domain association.
    enable_auto_sub_domain = optional(bool, false) # Enable auto sub domain for the domain association.
    sub_domains = optional(map(object({
      branch_name = string                       # The branch name for the sub domain.
      prefix      = string                       # The prefix for the sub domain.
    })))                                         # The sub domains for the domain association.
    wait_for_verification = optional(bool, true) # Wait for verification for the domain association.
  }))
  default = null
}

###########################
# General Variables
###########################

variable "tags" {
  description = "Tags for the Amplify App."
  type        = map(string)
}
