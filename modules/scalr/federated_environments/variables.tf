###########################
# Resource Variables
###########################
variable "federated_environments" {
  description = <<-EOT
    Map of scalr_federated_environments resources to create, keyed by a caller-chosen logical
    name. Each entry manages the list of federated environments for one "hub" environment.
    Fields:
      - environment_id:         (Required) The ID of an environment that federates access to other
                                environments, in the format "env-<RANDOM STRING>".
      - federated_environments: (Required) Set of environment identifiers that are allowed to
                                access the environment that federates access. Use ["*"] to allow all
                                environments.
  EOT
  type = map(object({
    environment_id         = string
    federated_environments = set(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.federated_environments : !contains(v.federated_environments, v.environment_id)
    ])
    error_message = "Each federated_environments entry's federated_environments set must not contain its own environment_id (an environment cannot federate access to itself)."
  }
}
