###########################
# Namespace Variables
###########################

variable "namespace" {
  description = "(Optional) When set, creates a Cloud Map HTTP namespace (via the namespace submodule) whose ARN is wired into the cluster (service_connect_defaults) and every service (service_connect_configuration). Mutually exclusive with `existing_namespace_arn`."
  type = object({
    name        = string
    description = optional(string)
  })
  default = null
}

variable "existing_namespace_arn" {
  description = "(Optional) Reference an existing Cloud Map namespace ARN instead of creating one. Mutually exclusive with `namespace`."
  type        = string
  default     = null
}

###########################
# Cluster Variables
###########################

variable "cluster" {
  description = "(Required) Cluster configuration object. Mirrors the `cluster` submodule variables (`name`, `container_insights`, `capacity_providers`, `default_capacity_provider_strategy`, execute-command logging toggles, etc.). At minimum, `name` is required."
  type        = any
}

###########################
# Capacity Provider Variables
###########################

variable "capacity_providers" {
  description = "(Optional) Map of EC2 capacity providers keyed by logical name (each mirrors the `capacity_provider` submodule). Created provider names are merged into the cluster's provider list."
  type        = map(any)
  default     = {}
}

###########################
# Task Definition Variables
###########################

variable "task_definitions" {
  description = "(Optional) Map of task definitions keyed by logical name (each mirrors the `task_definition` submodule). The map key is what services reference via their `task_definition` field."
  type        = map(any)
  default     = {}
}

###########################
# Service Variables
###########################

variable "services" {
  description = "(Optional) Map of services keyed by logical name (each mirrors the `service` submodule) plus a `task_definition` field naming a `task_definitions` key. The root resolves that key to the produced task-definition ARN and injects `cluster_arn` automatically."
  type        = map(any)
  default     = {}
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) A map of tags merged into every child module's tags."
  type        = map(string)
  default     = {}
}
