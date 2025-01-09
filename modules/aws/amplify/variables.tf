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
    basic_auth_credentials        = optional(string)      # Basic auth credentials for the branch. Must be input as "username:password".
    build_spec                    = optional(string)      # Build spec for the branch.
    enable_auto_build             = optional(bool)        # Enable auto build for the branch.
    enable_basic_auth             = optional(bool)        # Enable basic auth for the branch.
    enable_performance_mode       = optional(bool)        # Enable performance mode for the branch.
    enable_pull_request_preview   = optional(bool)        # Enable pull request preview for the branch.
    environment_variables         = optional(map(string)) # Map of environment variables for the branch.
    framework                     = optional(string)      # The framework for the branch.
    pull_request_environment_name = optional(string)      # The name of the pull request environment.
    stage                         = optional(string)      # Description of the stage. Valid values are PRODUCTION, BETA, DEVELOPMENT, EXPERIMENTAL, PULL_REQUEST.
  }))
  default = null
}

variable "auto_branch_creation_patterns" {
  description = "Patterns for auto branch creation."
  type        = list(string)
  default     = null
}

variable "basic_auth_credentials" {
  description = "Basic auth credentials for the Amplify App. Must be input as 'username:password'."
  type        = string
  sensitive   = true
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
  description = "Custom headers string for the Amplify App."
  type        = string
  default     = null
}

variable "custom_rules" {
  description = "List of custom rules for the Amplify App."
  type = list(object({
    condition = optional(string) # Condition for a URL redirect or rewrite.
    source    = string           # Source pattern for URL redirect or rewrite.
    status    = optional(string) # Status code for URL redirect or rewrite. Valid values are 200, 301, 302, 404, 404-200.
    target    = string           # Target pattern for URL redirect or rewrite.
  }))
  default = null
  # Example:
  # custom_rules = [
  #   {
  #     source = "/<*>"
  #     status = "404-200"
  #     target = "/404"
  #   },
  #   {
  #     source = "https://www.example.org"
  #     status = "301"
  #     target = "https://example.org"
  #   }
  # ]
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
  description = "A map of branches for the Amplify App. The key becomes the branch name and the value is an object of branch attributes or settings."
  type = map(object({
    basic_auth_credentials        = optional(string)                    # Basic auth credentials for the branch. Must be input as "username:password".
    certificate_type              = optional(string, "AMPLIFY_MANAGED") # The certificate type for the domain association. Valid values are AMPLIFY_MANAGED or CUSTOM.
    custom_certificate_arn        = optional(string)                    # The ARN for the custom certificate.
    description                   = optional(string)                    # The description of the branch.
    display_name                  = optional(string)                    # The display name of the branch. This gets used as the default domain prefix.
    domain_name                   = string                              # The domain name for the domain association.
    enable_auto_build             = optional(bool, true)                # Enable auto build for the branch.
    enable_auto_sub_domain        = optional(bool, false)               # Enable auto sub domain for the domain association.
    enable_basic_auth             = optional(bool)                      # Enable basic auth for the branch.
    enable_certificate            = optional(bool, true)                # Enable certificate for the domain association.
    enable_notification           = optional(bool)                      # Enable notification for the branch.
    enable_performance_mode       = optional(bool)                      # Enable performance mode for the branch.
    enable_pull_request_preview   = optional(bool)                      # Enable pull request preview for the branch.
    environment_variables         = optional(map(string))               # Map of environment variables for the branch.
    framework                     = optional(string)                    # The framework for the branch.
    pull_request_environment_name = optional(string)                    # The name of the pull request environment.
    stage                         = optional(string)                    # The stage for the branch. Valid values are PRODUCTION, BETA, DEVELOPMENT, EXPERIMENTAL, PULL_REQUEST.
    sub_domains                   = optional(set(string))               # A list of sub domains to associate with the branch.
    ttl                           = optional(number)                    # The TTL for the branch.
    wait_for_verification         = optional(bool, true)                # Wait for verification for the domain association.
  }))
  # Example:
  # branches = {
  #   main = {
  #     domain_name  = "example.org"
  #     framework    = "Astro"
  #     stage        = "PRODUCTION"
  #     sub_domains  = ["www"]
  #   },
  #   staging = {
  #     basic_auth_credentials = var.example_basic_auth_credentials
  #     domain_name            = "staging.example.org"
  #     enable_basic_auth      = true
  #     framework              = "Astro"
  #   },
  #   dev = {
  #     basic_auth_credentials = var.example_basic_auth_credentials
  #     domain_name            = "dev.example.org"
  #     enable_basic_auth      = true
  #     framework              = "Astro"
  #   }
}

###########################
# General Variables
###########################

variable "tags" {
  description = "Tags for the Amplify App."
  type        = map(string)
  default = {
    created_by  = "terraform" # Your name goes here
    terraform   = "true"
    environment = "prod"
  }
}
