###########################
# Scalr Agent Pool Token
###########################

variable "agent_pool_tokens" {
  description = <<-EOT
    (Required) Map of Scalr agent pool tokens (`scalr_agent_pool_token`) to create, keyed by a caller-chosen
    logical name.
    Fields:
      - agent_pool_id: (Required) ID of the agent pool, in the format `apool-<RANDOM STRING>`.
      - description:   (Optional) Description of the token.
  EOT
  type = map(object({
    agent_pool_id = string
    description   = optional(string)
  }))
  default = {}
}
