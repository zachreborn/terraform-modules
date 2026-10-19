###########################
# Resource Variables
###########################
variable "modules" {
  description = <<-EOT
    Map of Scalr Private Module Registry entries (scalr_module) to create, keyed by a
    caller-chosen logical name. Each entry is sourced either from a VCS repository or from an
    OCI registry; set exactly one of the two groups of fields below.

    VCS-sourced entries (both fields are required together):
      - vcs_provider_id:     (Required for VCS) The identifier of a VCS provider, in the format "vcs-<RANDOM STRING>".
      - vcs_repo.identifier: (Required for VCS) The identifier of a VCS repository, in the format ":org/:repo"
                            (":org/:project/:name" for Azure DevOps).
      - vcs_repo.path:       (Optional) The path to the root module folder. Expected to have the format
                            "<path>/terraform-<provider_name>-<module_name>".
      - vcs_repo.tag_prefix: (Optional) Registry ignores tags which do not match this prefix, e.g. "aws/".

    OCI-sourced entries (docker_image and docker_integration_id are required together, and so are
    name and module_provider; requires scalr provider >= 3.20.0):
      - docker_image:          (Required for OCI) The OCI repository path of the module inside the registry configured
                              in docker_integration_id, e.g. "scalr/terraform-aws-network". The registry host prefix,
                              e.g. "ghcr.io/", is optional. Conflicts with vcs_repo.
      - docker_integration_id: (Required for OCI) The identifier of a Docker registry integration (scalr_docker_integration)
                              the module is pulled from. Conflicts with vcs_provider_id.
      - name:                  (Required for OCI) Name of the module, e.g. "network".
      - module_provider:       (Required for OCI) Module provider name, e.g. "aws".

    Fields common to both source types:
      - namespace_id:        (Optional) A literal, externally-managed module namespace ID (format
                            "modns-<RANDOM STRING>"). Conflicts with environment_id and namespace_key.
      - namespace_key:       (Optional) The map key of an entry in var.module_namespaces whose ID is
                            resolved internally by this module (composition wiring). Conflicts with
                            environment_id and namespace_id.
      - module_provider:     (Optional for VCS, required for OCI) Module provider name, e.g. "aws", "azurerm",
                            "google". Must be set together with name.
      - name:                (Optional for VCS, required for OCI) Name of the module, e.g. "rds", "compute",
                            "kubernetes-engine". Must be set together with module_provider.
      - account_id:          (Optional, DEPRECATED by the upstream provider in favor of namespace_id/
                            namespace_key) The identifier of the account, in the format "acc-<RANDOM STRING>".
                            If set and namespace_id/namespace_key are not, the module is registered
                            globally, available across the whole installation. Still exposed here for
                            full argument coverage of the provider resource.
      - environment_id:      (Optional, DEPRECATED by the upstream provider in favor of namespace_id/
                            namespace_key) The identifier of an environment, in the format "env-<RANDOM STRING>".
                            Conflicts with namespace_id/namespace_key. Still exposed here for full
                            argument coverage of the provider resource.

    Examples:
      modules = {
        vpc = { # VCS-sourced
          vcs_provider_id = "vcs-xxxxxxxxxx"
          vcs_repo = {
            identifier = "my-org/terraform-aws-vpc"
          }
        }
        network = { # OCI-sourced
          docker_integration_id = "in-xxxxxxxxxx"
          docker_image          = "my-org/terraform-aws-network"
          module_provider       = "aws"
          name                  = "network"
        }
      }
  EOT
  type = map(object({
    vcs_provider_id = optional(string)
    vcs_repo = optional(object({
      identifier = string
      path       = optional(string)
      tag_prefix = optional(string)
    }))
    docker_image          = optional(string)
    docker_integration_id = optional(string)
    namespace_id          = optional(string)
    namespace_key         = optional(string)
    module_provider       = optional(string)
    name                  = optional(string)
    account_id            = optional(string)
    environment_id        = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.modules : !(v.namespace_id != null && v.namespace_key != null)
    ])
    error_message = "Each modules entry must not set both namespace_id and namespace_key; set at most one."
  }

  # Conditional expressions (not `x == null || f(x)`) because Terraform evaluates both operands of
  # ||/&& and f(null) would raise an evaluation error for entries that omit the optional field.
  validation {
    condition = alltrue([
      for k, v in var.modules : v.namespace_key == null ? true : contains(keys(var.module_namespaces), v.namespace_key)
    ])
    error_message = "Each modules namespace_key must reference an existing key in var.module_namespaces."
  }

  validation {
    condition = alltrue([
      for k, v in var.modules : !((v.namespace_id != null || v.namespace_key != null) && v.environment_id != null)
    ])
    error_message = "Each modules entry must not set environment_id together with namespace_id/namespace_key; the upstream provider documents namespace_id as conflicting with environment_id."
  }

  validation {
    condition = alltrue([
      for k, v in var.modules : v.vcs_repo == null ? true : v.vcs_repo.identifier != ""
    ])
    error_message = "Each modules entry's vcs_repo.identifier must be a non-empty string, e.g. \"org/repo\"."
  }

  # Source selection: a module is sourced either from VCS (vcs_provider_id + vcs_repo) or from an
  # OCI registry (docker_image + docker_integration_id), never both and never neither. The checks
  # are split so each failure produces a specific message.
  validation {
    condition = alltrue([
      for k, v in var.modules : !((v.vcs_provider_id != null || v.vcs_repo != null) && (v.docker_image != null || v.docker_integration_id != null))
    ])
    error_message = "Each modules entry must be sourced from either VCS (vcs_provider_id + vcs_repo) or an OCI registry (docker_image + docker_integration_id), not both."
  }

  validation {
    condition = alltrue([
      for k, v in var.modules : (v.vcs_provider_id != null) == (v.vcs_repo != null)
    ])
    error_message = "Each modules entry must set vcs_provider_id and vcs_repo together (VCS-sourced modules require both)."
  }

  validation {
    condition = alltrue([
      for k, v in var.modules : (v.docker_image != null) == (v.docker_integration_id != null)
    ])
    error_message = "Each modules entry must set docker_image and docker_integration_id together (OCI-sourced modules require both)."
  }

  validation {
    condition = alltrue([
      for k, v in var.modules : v.vcs_repo != null || v.docker_image != null
    ])
    error_message = "Each modules entry must declare a source: either vcs_provider_id + vcs_repo (VCS) or docker_image + docker_integration_id (OCI)."
  }

  validation {
    condition = alltrue([
      for k, v in var.modules : v.docker_image == null ? true : trimspace(v.docker_image) != ""
    ])
    error_message = "Each modules entry's docker_image must be a non-empty OCI repository path, e.g. \"my-org/terraform-aws-network\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.modules : v.docker_image == null || (v.name != null && v.module_provider != null)
    ])
    error_message = "Each OCI-sourced modules entry (docker_image set) must also set name and module_provider; Scalr cannot derive them from a repository path."
  }

  # The provider requires name and module_provider together (AlsoRequires in both directions).
  validation {
    condition = alltrue([
      for k, v in var.modules : (v.name != null) == (v.module_provider != null)
    ])
    error_message = "Each modules entry must set name and module_provider together, or neither."
  }
}

variable "module_namespaces" {
  description = <<-EOT
    Map of Scalr Module Namespaces (scalr_module_namespace) to create via the companion
    ./namespace submodule, keyed by a caller-chosen logical name. See ./namespace/variables.tf
    for the full field list. Reference an entry from var.modules by setting that entry's
    namespace_key to this map's key.
  EOT
  type = map(object({
    name         = optional(string)
    environments = optional(set(string))
    is_shared    = optional(bool)
    owners       = optional(set(string))
  }))
  default = {}
}
