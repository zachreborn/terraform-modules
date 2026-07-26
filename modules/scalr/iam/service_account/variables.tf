###########################
# Resource Variables
###########################
variable "service_accounts" {
  description = <<-EOT
    (Optional) Map of Scalr Service Accounts to create, keyed by a caller-chosen logical name (e.g.
    "ci"). Each entry:
      - name:        (Optional) Name of the service account. Defaults to the entry's map key when
                      unset.
      - account_id:  (Optional) ID of the account, in the format 'acc-'. Falls back to
                      var.account_id when unset.
      - description: (Optional) Description of the service account.
      - owners:       (Optional) Set of team IDs the service account belongs to.
      - status:       (Optional) The status of the service account. One of "Active" or "Inactive".
                      Defaults to "Active".
  EOT
  type = map(object({
    name        = optional(string)
    account_id  = optional(string)
    description = optional(string)
    owners      = optional(set(string))
    status      = optional(string, "Active")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.service_accounts : v != null
    ])
    error_message = "Each service_accounts entry must be an object; bare/null entries are not supported."
  }

  validation {
    condition = alltrue([
      for k, v in var.service_accounts : v != null ? contains(["Active", "Inactive"], v.status) : true
    ])
    error_message = "Each service_accounts entry's status must be one of 'Active' or 'Inactive'."
  }
}

###########################
# Service Account Token Variables
###########################
variable "tokens" {
  description = <<-EOT
    (Optional) Map of Scalr Service Account tokens to create, forwarded as-is to the nested
    modules/scalr/iam/service_account/token submodule. Each entry must set exactly one of
    service_account_id (a literal ID) or service_account_key (a key into this same module call's
    var.service_accounts). See that submodule's variables.tf for the full field list.
  EOT
  type = map(object({
    service_account_id  = optional(string)
    service_account_key = optional(string)
    description         = optional(string)
    expires_in          = optional(number)
    name                = optional(string)
  }))
  default = {}
}

###########################
# Assume Service Account Policy Variables
###########################
variable "assume_policies" {
  description = <<-EOT
    (Optional) Map of Scalr Assume Service Account Policies to create, forwarded as-is to the nested
    modules/scalr/iam/service_account/assume_policy submodule. Each entry must set exactly one of
    service_account_id (a literal ID) or service_account_key (a key into this same module call's
    var.service_accounts). See that submodule's variables.tf for the full field list.
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
}

###########################
# General Variables
###########################
variable "account_id" {
  description = "(Optional) Default ID of the account, in the format 'acc-', used for any service_accounts entry that does not set its own account_id."
  type        = string
  default     = null
}
