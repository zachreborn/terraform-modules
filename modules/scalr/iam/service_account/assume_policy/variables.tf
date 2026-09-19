###########################
# Resource Variables
###########################
variable "assume_policies" {
  description = <<-EOT
    (Optional) Map of Scalr Assume Service Account Policies to create, keyed by a caller-chosen
    logical name (e.g. "ga-scalr-staging"). Each entry must set exactly one of:
      - service_account_id:  A literal Scalr Service Account ID (format 'sa-') this policy is
                              attached to.
      - service_account_key: A key into var.service_account_ids (e.g. the `ids` output of
                              modules/scalr/iam/service_account) identifying the service account this
                              policy is attached to.
    Other fields:
      - name:                     (Optional) The name of the policy. Defaults to the entry's map key
                                   when unset.
      - provider_id:              (Required) The ID of the Workload Identity Provider (format
                                   'wip-') associated with this policy.
      - maximum_session_duration: (Optional) The maximum session duration in seconds for the assumed
                                   role.
      - claim_conditions:         (Required, non-empty) List of claim conditions the caller's OIDC
                                   token must satisfy to assume the service account. The provider's
                                   published docs list this block as Optional, but the real v3.17.0
                                   provider schema rejects a plan with zero claim_condition blocks
                                   ("Block claim_condition must have a configuration value as the
                                   provider has marked it as required") -- verified directly against
                                   the downloaded provider binary. This module therefore requires at
                                   least one entry, which also matches secure-by-default practice: a
                                   policy with no claim conditions would otherwise let any holder of a
                                   valid OIDC token from the associated provider assume the service
                                   account.
                                     - claim:    (Required) The claim to match (e.g. "sub").
                                     - value:    (Required) The value to match for the claim.
                                     - operator: (Optional) One of "eq", "contains", "startswith",
                                                 "endswith", or "like". Defaults to the provider's own
                                                 default when unset.
  EOT
  type = map(object({
    service_account_id       = optional(string)
    service_account_key      = optional(string)
    name                     = optional(string)
    provider_id              = string
    maximum_session_duration = optional(number)
    claim_conditions = optional(list(object({
      claim    = string
      value    = string
      operator = optional(string)
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.assume_policies : v != null
    ])
    error_message = "Each assume_policies entry must be an object; bare/null entries are not supported."
  }

  validation {
    condition = alltrue([
      for k, v in var.assume_policies : v != null ? (v.service_account_id != null) != (v.service_account_key != null) : true
    ])
    error_message = "Each assume_policies entry must set exactly one of service_account_id or service_account_key."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.assume_policies : v != null ? [
        for c in v.claim_conditions : c.operator == null || contains(["eq", "contains", "startswith", "endswith", "like"], c.operator)
      ] : []
    ]))
    error_message = "Each claim_conditions entry's operator, if set, must be one of 'eq', 'contains', 'startswith', 'endswith', or 'like'."
  }

  validation {
    condition = alltrue([
      for k, v in var.assume_policies : v != null ? length(v.claim_conditions) > 0 : true
    ])
    error_message = "Each assume_policies entry must set at least one claim_conditions entry -- the provider rejects a plan with zero claim_condition blocks despite documenting the block as Optional."
  }
}

variable "service_account_ids" {
  description = "(Optional) Map of Scalr Service Account IDs keyed by logical name, e.g. the `ids` output of modules/scalr/iam/service_account. Referenced by each assume_policies entry's service_account_key."
  type        = map(string)
  default     = {}
}
