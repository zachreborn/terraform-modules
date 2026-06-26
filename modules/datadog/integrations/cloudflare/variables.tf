###########################
# Resource Variables
###########################
variable "cloudflare_accounts" {
  description = "Map of Cloudflare account integrations keyed by a logical name. The api_key field is sensitive — mark the whole variable sensitive to prevent leakage."
  type = map(object({
    api_key   = string
    name      = string
    email     = optional(string)
    resources = optional(set(string))
  }))
  default = {}
}
