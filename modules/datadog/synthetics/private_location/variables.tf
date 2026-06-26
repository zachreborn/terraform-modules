###########################
# Resource Variables
###########################
variable "private_locations" {
  description = "Map of Synthetics private location configurations keyed by logical name. The api_key field is sensitive — pass it via a sensitive variable or use Terraform state encryption."
  type = map(object({
    name        = string
    description = optional(string, "")
    tags        = optional(list(string), [])
    api_key     = optional(string, null)
    metadata = optional(object({
      restricted_roles = optional(set(string), null)
    }), null)
  }))
  default = {}
}
