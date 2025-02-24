###########################
# Resource Variables
###########################

###########################
# General Variables
###########################

variable "enabled_features" {
  description = "A list of IAM organization features which will be enabled. Valid values are RootCredentialsManagement and RootSessions."
  type        = list(string)
  default = [
    "RootCredentialsManagement",
    "RootSessions"
  ]
}
