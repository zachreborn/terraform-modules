###########################
# Global Network Variables
###########################
variable "name" {
  description = "(Required) Name of the global network."
  type        = string
}

variable "description" {
  description = "(Optional) Description of the global network."
  type        = string
  default     = null
}

###########################
# General Variables
###########################
variable "tags" {
  description = "(Optional) Map of tags to assign to the resource."
  type        = map(any)
  default = {
    created_by  = "terraform"
    terraform   = "true"
    environment = "prod"
  }
}
