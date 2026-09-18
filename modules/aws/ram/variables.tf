###########################
# Resource Variables
###########################

variable "allow_external_principals" {
  description = "Indicates whether principals outside your AWS organization can be associated with a resource share."
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

variable "resource_arns" {
  description = "List of resource ARNs to associate with the resource share."
  type        = list(string)
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
