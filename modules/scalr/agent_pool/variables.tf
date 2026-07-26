###########################
# Scalr Agent Pool
###########################

variable "agent_pools" {
  description = <<-EOT
    (Optional) Map of Scalr agent pools (`scalr_agent_pool`) to create, keyed by a caller-chosen logical name
    (e.g. "default"). This key can also be referenced by var.agent_pool_tokens entries via agent_pool_key.
    Fields:
      - name:            (Optional) Name of the agent pool. Defaults to the entry's map key when unset.
      - account_id:      (Optional, Deprecated by the provider in favor of `environments`) ID of the account
                         that owns the pool.
      - environment_id:  (Optional, Deprecated by the provider in favor of `environments`) ID of a single
                         environment that owns the pool.
      - environments:    (Optional) Set of environment IDs the agent pool is shared to. Use ["*"] to share
                         with all environments.
      - vcs_enabled:     (Optional) Whether VCS support is enabled for agents in the pool. Defaults to false.
      - api_gateway_url: (Optional) HTTP(s) destination URL for the pool's webhook.
      - headers:         (Optional) List of additional headers to set on the pool's webhook request. Each
                         entry sets name (required), value (required, ignored when sensitive = true -- see
                         var.agent_pool_header_values), and sensitive (optional, defaults to false, whether
                         the header value is masked in the Scalr UI). Defaults to an empty list.
  EOT
  type = map(object({
    name            = optional(string)
    account_id      = optional(string)
    environment_id  = optional(string)
    environments    = optional(set(string))
    vcs_enabled     = optional(bool, false)
    api_gateway_url = optional(string)
    headers = optional(list(object({
      name      = string
      value     = string
      sensitive = optional(bool, false)
    })), [])
  }))
  default = {}
}

variable "agent_pool_header_values" {
  description = <<-EOT
    Map of sensitive agent pool webhook header values, keyed by the agent pool's logical name
    (matching a key in var.agent_pools) and then by header name. Populate an entry here instead
    of setting 'value' directly on a headers entry whenever that header sets 'sensitive = true':
    the provider's sensitive flag only controls masking in the Scalr UI and does not prevent the
    value from appearing in Terraform/OpenTofu plan output when sourced from a non-sensitive
    variable.

    Example:
      agent_pool_header_values = {
        default = {
          Authorization = "Bearer my-secret-token"
        }
      }
  EOT
  type        = map(map(string))
  sensitive   = true
  default     = {}
}

###########################
# Scalr Agent Pool Tokens
###########################

variable "agent_pool_tokens" {
  description = <<-EOT
    (Optional) Map of agent pool tokens to create via the companion ./token submodule, keyed by a
    caller-chosen logical name. Each entry must set exactly one of:
      - agent_pool_id:  A literal agent pool ID, in the format `apool-<RANDOM STRING>` (e.g. for a pool managed
                        outside this module call).
      - agent_pool_key: A key into var.agent_pools, resolving to the ID of an agent pool created by this same
                        module call. An unknown key fails naturally when OpenTofu/Terraform tries to index
                        scalr_agent_pool.this by that key.
    Fields:
      - agent_pool_id:  (Optional) Literal agent pool ID. Conflicts with agent_pool_key.
      - agent_pool_key: (Optional) Key into var.agent_pools. Conflicts with agent_pool_id.
      - description:    (Optional) Description of the token.
  EOT
  type = map(object({
    agent_pool_id  = optional(string)
    agent_pool_key = optional(string)
    description    = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.agent_pool_tokens : (v.agent_pool_id != null) != (v.agent_pool_key != null)
    ])
    error_message = "Each agent_pool_tokens entry must set exactly one of agent_pool_id or agent_pool_key."
  }
}
