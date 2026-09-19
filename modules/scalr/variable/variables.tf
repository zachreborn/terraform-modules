###########################
# Scalr Variable
###########################

variable "variables" {
  description = <<-EOT
    (Required) Map of Scalr variables (`scalr_variable`) to create, keyed by a caller-chosen logical name.
    This variable intentionally excludes the variable's actual value -- see var.values / var.values_wo below.
    Fields:
      - key:              (Required) Key of the variable.
      - category:         (Optional) Either "terraform" or "shell". Defaults to "terraform".
      - hcl:               (Optional) Whether the value is a string of HCL code. Has no effect for shell
                           variables. Defaults to false.
      - sensitive:        (Optional) Whether the value is sensitive (masked after being set). Defaults to false.
      - final:            (Optional) Whether the variable can be overridden on a lower scope. Defaults to false.
      - force:            (Optional) Whether to force-create a final variable even if the same variable
                           already exists on a lower scope (which is then deleted). Defaults to false.
      - description:      (Optional) Verbose description of the variable.
      - account_id:       (Optional) ID of the account that owns the variable, in the format `acc-<RANDOM STRING>`.
      - environment_id:   (Optional) ID of the environment that owns the variable, in the format `env-<RANDOM STRING>`.
      - workspace_id:     (Optional) ID of the workspace that owns the variable, in the format `ws-<RANDOM STRING>`.
      - var_set_id:       (Optional) ID of the variable set this variable belongs to, in the format
                           `varset-<RANDOM STRING>`.
      - value_wo_version: (Optional) Version number for the corresponding var.values_wo entry. Increment this
                           number to apply an updated write-only value. Only relevant when a var.values_wo entry
                           is set for this key.
    Exactly one of account_id, environment_id, workspace_id, or var_set_id must be set per entry -- this defines
    the scope the variable is created in.
  EOT
  type = map(object({
    key              = string
    category         = optional(string, "terraform")
    hcl              = optional(bool, false)
    sensitive        = optional(bool, false)
    final            = optional(bool, false)
    force            = optional(bool, false)
    description      = optional(string)
    account_id       = optional(string)
    environment_id   = optional(string)
    workspace_id     = optional(string)
    var_set_id       = optional(string)
    value_wo_version = optional(number)
  }))

  validation {
    condition = alltrue([
      for k, v in var.variables : contains(["terraform", "shell"], v.category)
    ])
    error_message = "Each variables entry's category must be either \"terraform\" or \"shell\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.variables : length([
        for scope in [v.account_id, v.environment_id, v.workspace_id, v.var_set_id] : scope if scope != null
      ]) == 1
    ])
    error_message = "Each variables entry must set exactly one of account_id, environment_id, workspace_id, or var_set_id."
  }
}

variable "values" {
  description = <<-EOT
    (Optional) Map of variable values (the `value` attribute of `scalr_variable`), keyed by the same keys as
    var.variables. Kept as a separate, always-sensitive variable rather than an attribute nested inside
    var.variables, since OpenTofu/Terraform cannot mark a single attribute of an object-typed variable as
    sensitive -- only whole variables can be marked sensitive. Splitting the value out keeps the rest of each
    entry's metadata (key, category, scope, etc.) visible in plan output while still guaranteeing the actual
    value is never displayed.
    An entry may be omitted here if the corresponding var.variables entry sets a value via var.values_wo instead.
  EOT
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "values_wo" {
  description = <<-EOT
    (Optional) Map of write-only variable values (the `value_wo` attribute of `scalr_variable`, supported on
    Terraform/OpenTofu 1.11+), keyed by the same keys as var.variables. Use this instead of var.values when the
    source value is itself ephemeral (e.g. sourced from an ephemeral resource or write-only data source) and
    must never be persisted to state. The corresponding var.variables entry's value_wo_version must be
    incremented whenever the value here changes, since OpenTofu/Terraform has no other way to detect that a
    write-only value changed.
  EOT
  type        = map(string)
  sensitive   = true
  default     = {}
}
