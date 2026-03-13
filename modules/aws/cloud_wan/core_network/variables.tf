###########################
# Core Network Variables
###########################
variable "name" {
  description = "(Required) Name of the core network."
  type        = string
}

variable "global_network_id" {
  description = "(Required) The ID of the global network that the core network is associated with."
  type        = string
}

variable "description" {
  description = "(Optional) Description of the core network."
  type        = string
  default     = null
}

variable "base_policy_regions" {
  description = "(Optional) List of regions for the base policy. Required if create_base_policy is true."
  type        = list(string)
  default     = null
}

variable "create_base_policy" {
  description = "(Optional) Whether to create a base policy. If true, base_policy_regions must be provided."
  type        = bool
  default     = false
}

variable "policy_document" {
  description = "(Optional) Policy document as a JSON string. Use the aws_networkmanager_core_network_policy_document data source to generate this."
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
