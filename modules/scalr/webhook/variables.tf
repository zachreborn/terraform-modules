###########################
# Resource Variables
###########################
variable "webhooks" {
  description = <<-EOT
    Map of Scalr webhooks keyed by a caller-supplied logical name. Each entry manages one
    `scalr_webhook` resource, which posts a payload to an external endpoint when one or more
    Scalr run events occur.

    Note: `secret_key` is intentionally NOT a field of this object. Supply it via the sibling
    `webhook_secret_keys` variable, keyed to the same logical name, so this variable (and any
    output derived from it) never needs to be marked sensitive.

    Fields:
      - name:         (Required) Name of the webhook.
      - url:          (Required) Endpoint URL.
      - events:       (Required) Set of event IDs, e.g. ["run:completed", "run:errored"].
      - account_id:   (Optional) ID of the account, in the format "acc-<RANDOM STRING>". Falls
                       back to var.account_id when unset.
      - enabled:      (Optional, default true) Whether the webhook is enabled.
      - environments: (Optional) Set of environment identifiers the webhook is shared to. Use
                       ["*"] to share with all environments.
      - header:       (Optional) Set of additional headers to send, each with `name` (required)
                       and `value` (optional -- omit it, and instead populate
                       var.webhook_header_values, for header values that contain a credential;
                       see that variable's description).
      - max_attempts: (Optional) Max delivery attempts of the payload.
      - timeout:      (Optional) Endpoint timeout, in seconds.

    Example:
      webhooks = {
        run_notifications = {
          name         = "run-notifications"
          url          = "https://my-endpoint.example.com"
          events       = ["run:completed", "run:errored"]
          environments = ["env-xxxxxxxxxx"]
          header = [
            { name = "X-Source", value = "scalr" },
            { name = "Authorization" } # value supplied via var.webhook_header_values instead
          ]
        }
      }
  EOT
  type = map(object({
    name         = string
    url          = string
    events       = set(string)
    account_id   = optional(string)
    enabled      = optional(bool, true)
    environments = optional(set(string))
    header = optional(set(object({
      name  = string
      value = optional(string)
    })), [])
    max_attempts = optional(number)
    timeout      = optional(number)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.webhooks : length(value.events) > 0
    ])
    error_message = "Each webhooks entry must specify at least one event in its 'events' set."
  }
}

variable "webhook_secret_keys" {
  description = "Map of secret_key values used to sign each webhook's payload, keyed to match the same logical name used in var.webhooks. Sensitive."
  type        = map(string)
  sensitive   = true
  default     = {}
  nullable    = false
}

variable "webhook_header_values" {
  description = <<-EOT
    Map of header values that contain a credential (e.g. an Authorization header), keyed by the
    webhook's logical name (matching a key in var.webhooks) and then by header name. Populate an
    entry here -- and omit 'value' on the corresponding header entry in var.webhooks -- for any
    header whose value should not appear in Terraform/OpenTofu plan output. The provider's webhook
    header schema has no 'sensitive' flag of its own (unlike agent_pool's), so var.webhooks itself
    cannot mark individual header values sensitive; routing the value through this separate,
    always-sensitive variable is the only way to keep it out of plan output.

    Example:
      webhook_header_values = {
        run_notifications = {
          Authorization = "Bearer my-secret-token"
        }
      }
  EOT
  type        = map(map(string))
  sensitive   = true
  default     = {}
  nullable    = false
}

###########################
# General Variables
###########################
variable "account_id" {
  description = "(Optional) Default Scalr account ID, in the format \"acc-<RANDOM STRING>\", used for any webhooks entry that does not set its own account_id."
  type        = string
  default     = null
}
