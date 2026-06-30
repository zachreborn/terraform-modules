###########################
# Resource Variables
###########################
variable "cloudflare_accounts" {
  description = "Map of Cloudflare account integrations keyed by a logical name. The api_key field is sensitive — pass it via an environment variable (TF_VAR_cloudflare_accounts), Terraform Cloud/HCP sensitive variables, or a secrets manager rather than in plain-text .tfvars files."
  type = map(object({
    api_key   = string
    name      = string
    email     = optional(string)
    resources = optional(set(string))
  }))
  default = {}
}
