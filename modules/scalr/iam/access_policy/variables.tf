###########################
# Resource Variables
###########################
variable "access_policies" {
  description = <<-EOT
    (Optional) Map of Scalr IAM access policies to create, keyed by a caller-chosen logical name
    (e.g. "team_read_all_on_acc_scope"). Each entry:
      - role_ids: (Required) Set of scalr_role IDs to grant. Must be non-empty.
      - subject:  (Required) Block identifying who the policy applies to:
                    - type: (Required) One of "user", "team", or "service_account".
                    - id:   (Required) The subject ID -- "user-" for a user, "team-" for a team, or
                            "sa-" for a service account.
      - scope:    (Required) Block identifying where the policy applies:
                    - type: (Required) One of "account", "environment", or "workspace".
                    - id:   (Required) The scope ID -- "acc-" for account, "env-" for environment, or
                            "ws-" for workspace.
  EOT
  type = map(object({
    role_ids = set(string)
    subject = object({
      type = string
      id   = string
    })
    scope = object({
      type = string
      id   = string
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.access_policies : v != null
    ])
    error_message = "Each access_policies entry must be an object; bare/null entries are not supported."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_policies : v != null ? length(v.role_ids) > 0 : true
    ])
    error_message = "Each access_policies entry must set a non-empty role_ids set."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_policies : v != null ? contains(["user", "team", "service_account"], v.subject.type) : true
    ])
    error_message = "Each access_policies entry's subject.type must be one of 'user', 'team', or 'service_account'."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_policies : v != null ? contains(["account", "environment", "workspace"], v.scope.type) : true
    ])
    error_message = "Each access_policies entry's scope.type must be one of 'account', 'environment', or 'workspace'."
  }
}
