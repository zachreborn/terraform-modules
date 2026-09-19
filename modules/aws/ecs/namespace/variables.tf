###########################
# Resource Variables
###########################

variable "name" {
  description = "(Required) The name of the Cloud Map HTTP namespace used for ECS Service Connect."
  type        = string
}

variable "description" {
  description = "(Optional) The description of the namespace."
  type        = string
  default     = null
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) A map of tags to assign to the namespace. A `Name` tag is merged automatically."
  type        = map(string)
  default     = {}
}
