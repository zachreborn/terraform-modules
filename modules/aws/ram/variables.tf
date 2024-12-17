###########################
# Resource Variables
###########################

variable "allow_external_principals" {
  description = "Indicates whether principals outside your AWS organization can be associated with a resource share."
  type        = bool
  default     = false
}

variable "enable_organization_sharing" {
  description = "Enable sharing with AWS Organizations."
  type        = bool
  default     = false
}

variable "name" {
  description = "The name of the resource share."
  type        = string
}

variable "permission_arns" {
  description = "The ARNs of the permissions to associate with the resource share."
  type        = list(string)
  default     = null
}

variable "principal" {
  description = "The principal to associate with the resource share."
  type        = string
  default     = null
}

variable "resource_arn" {
  description = "The ARN of the resource to associate with the resource share."
  type        = string
}

###########################
# General Variables
###########################

variable "tags" {
  description = "A mapping of tags to assign to the resource share."
  type        = map(string)
  default = {
    created_by  = "terraform" # Your name goes here
    terraform   = "true"
    environment = "prod"
  }
}
