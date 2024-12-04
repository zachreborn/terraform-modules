###########################
# Resource Variables
###########################

###########################
# Amplify App
###########################

variable "access_token" {
  description = "Access token for the Amplify App"
  type        = string
}

variable "auto_branch_creation_patterns" {
  description = "Patterns for auto branch creation"
  type        = list(string)
}

variable "basic_auth_credentials" {
  description = "Basic auth credentials for the Amplify App"
  type        = string
}

variable "build_spec" {
  description = "Build spec for the Amplify App"
  type        = string
}

###########################
# General Variables
###########################

