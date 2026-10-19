###########################
# Resource Variables
###########################
variable "module_test_configurations" {
  description = <<-EOT
    Map of Scalr module test configurations (`scalr_module_test_configuration`) to manage, keyed by a
    caller-chosen logical name. Each entry manages the `tofu test` configuration of one module in the
    Private Module Registry.

    A module has exactly one test configuration, so module_id must be unique across the entries of this
    map. Scalr has no delete endpoint for a test configuration: destroying an entry disables it
    (enabled = false) rather than removing it.

    Fields:
      - module_id:                      (Required) ID of the module, in the format "mod-<RANDOM STRING>".
      - enabled:                        (Optional) Whether the test configuration is enabled. Defaults to true.
      - failure_behavior:               (Optional) The behavior to apply when a test run fails. Valid values are
                                        "failure" and "notify". Defaults to "notify".
      - trigger_on_new_version_enabled: (Optional) Whether a test run is triggered when a new module version is
                                        synced. Defaults to false.
      - trigger_on_pr_activity_enabled: (Optional) Whether a test run is triggered on pull request activity.
                                        Defaults to false.

    Example:
      module_test_configurations = {
        vpc = {
          module_id                      = "mod-xxxxxxxxxx"
          failure_behavior               = "failure"
          trigger_on_new_version_enabled = true
          trigger_on_pr_activity_enabled = true
        }
      }
  EOT
  type = map(object({
    module_id                      = string
    enabled                        = optional(bool, true)
    failure_behavior               = optional(string, "notify")
    trigger_on_new_version_enabled = optional(bool, false)
    trigger_on_pr_activity_enabled = optional(bool, false)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.module_test_configurations : trimspace(value.module_id) != ""
    ])
    error_message = "Each module_test_configurations entry's module_id must be a non-empty module ID, e.g. 'mod-xxxxxxxxxx'."
  }

  validation {
    condition = alltrue([
      for key, value in var.module_test_configurations : contains(["failure", "notify"], value.failure_behavior)
    ])
    error_message = "Each module_test_configurations entry's failure_behavior must be 'failure' or 'notify'."
  }

  validation {
    condition     = length(distinct([for key, value in var.module_test_configurations : value.module_id])) == length(var.module_test_configurations)
    error_message = "Each module_test_configurations entry must use a unique module_id; a module has exactly one test configuration, so duplicate entries would manage the same remote object."
  }
}
