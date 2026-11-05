###########################
# Resource Variables
###########################
variable "policy_groups" {
  description = <<-EOT
    Map of Scalr Policy Groups (scalr_policy_group) to create, keyed by a caller-chosen logical
    name (e.g. "instance_types"). Fields:
      - name:                    (Optional) Name of the policy group. Defaults to the entry's map key.
      - account_id:               (Optional) The identifier of the Scalr account, in the format "acc-<RANDOM STRING>".
      - vcs_provider_id:          (Required) The identifier of a VCS provider, in the format "vcs-<RANDOM STRING>".
      - vcs_repo.identifier:      (Required) The reference to the VCS repository, in the format ":org/:repo".
      - vcs_repo.branch:          (Optional) The branch of the repository the policy group is associated with.
                                  Defaults to the repository's default branch when unset.
      - vcs_repo.path:            (Optional) The subdirectory of the VCS repository where OPA policies are
                                  stored. Defaults to the repository root when unset.
      - opa_version:              (Optional) The version of Open Policy Agent to run policies against.
                                  Defaults to the system default version when unset.
      - evaluate_on:              (Optional) The stage of the run at which the policy group is evaluated. One of
                                  "pre-plan" or "post-plan". When unset on creation, the provider defaults to
                                  "post-plan". WARNING: changing this value on an existing policy group forces the
                                  policy group to be destroyed and RE-CREATED (the upstream provider marks it
                                  RequiresReplace), so it gets a new ID. Review the plan before applying a change.
                                  Requires provider >= 3.20.0.
      - common_functions_folder:  (Optional) An absolute path from the repository root to the folder that
                                  contains common rego functions.
      - environments:             (Optional) Set of environment IDs the policy group is linked to. Use
                                  ["*"] to enforce in all environments. To manage linkages, use either this
                                  attribute or var.policy_group_linkages (backed by the companion
                                  ./linkage submodule) -- not both for the same environment.
  EOT
  type = map(object({
    name            = optional(string)
    account_id      = optional(string)
    vcs_provider_id = string
    vcs_repo = object({
      identifier = string
      branch     = optional(string)
      path       = optional(string)
    })
    opa_version             = optional(string)
    evaluate_on             = optional(string)
    common_functions_folder = optional(string)
    environments            = optional(set(string))
  }))
  default = {}

  validation {
    # Note: intentionally not calling coalesce(v.name, k) here -- coalesce() raises a hard
    # evaluation error ("no non-null, non-empty-string arguments") rather than returning
    # false when every argument is null/empty, which would crash validation entirely for an
    # empty key + omitted name instead of surfacing the error_message below. This ternary
    # reproduces coalesce()'s "first non-null, non-empty-string value" semantics without
    # ever calling it on an all-invalid input.
    condition = alltrue([
      for k, v in var.policy_groups : (v.name != null && v.name != "" ? v.name : k) != ""
    ])
    error_message = "Each policy_groups entry must resolve to a non-empty name (set name explicitly or use a non-empty map key)."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_groups : v.vcs_repo.identifier != ""
    ])
    error_message = "Each policy_groups entry's vcs_repo.identifier must be a non-empty string, e.g. \"org/repo\"."
  }

  validation {
    # A conditional, not `v.evaluate_on == null || contains(...)`: Terraform evaluates both operands of `||`,
    # so contains() would still be called with null for an omitted evaluate_on and raise "argument must not
    # be null". A conditional only reports errors from the branch it selects.
    condition = alltrue([
      for k, v in var.policy_groups : v.evaluate_on == null ? true : contains(["pre-plan", "post-plan"], v.evaluate_on)
    ])
    error_message = "Each policy_groups entry's evaluate_on must be null, \"pre-plan\", or \"post-plan\". Note that changing evaluate_on on an existing policy group forces it to be re-created."
  }
}

variable "policy_group_linkages" {
  description = <<-EOT
    Map of scalr_policy_group_linkage resources to create, keyed by a caller-chosen logical name.
    Each entry links one policy group to one environment. Set exactly one of:
      - policy_group_key: The map key of an entry in var.policy_groups whose ID is resolved internally
                          by this module (composition wiring).
      - policy_group_id:  A literal, externally-managed policy group ID (format "pgrp-<RANDOM STRING>").
    Fields:
      - environment_id: (Required) ID of the environment, in the format "env-<RANDOM STRING>".
  EOT
  type = map(object({
    policy_group_key = optional(string)
    policy_group_id  = optional(string)
    environment_id   = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.policy_group_linkages : (v.policy_group_key != null) != (v.policy_group_id != null)
    ])
    error_message = "Each policy_group_linkages entry must set exactly one of policy_group_key or policy_group_id."
  }

  validation {
    condition = alltrue([
      for k, v in var.policy_group_linkages : v.policy_group_key == null || contains(keys(var.policy_groups), v.policy_group_key)
    ])
    error_message = "Each policy_group_linkages policy_group_key must reference an existing key in var.policy_groups."
  }
}
