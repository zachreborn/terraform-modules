###########################################################
# Wiring / harness module proving a hook's ID flows into the
# companion environment_link submodule as a resource-argument
# value (not a for_each key), mirroring
# modules/aws/organizations/delegated_admin/tests/wiring.
###########################################################

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.17.0"
    }
  }
}

module "hook" {
  source = "../.."

  hooks = {
    notify = {
      name            = "notify"
      interpreter     = "bash"
      scriptfile_path = "hooks/notify.sh"
      vcs_provider_id = "vcs-xxxxxxxxxx"
      vcs_repo = {
        identifier = "my-org/my-hooks-repo"
      }
    }
  }
}

module "hook_environment_link" {
  source = "../../environment_link"

  environment_hooks = {
    notify_prod = {
      hook_id        = module.hook.ids["notify"]
      environment_id = "env-xxxxxxxxxx"
      events         = ["pre-apply", "post-apply"]
    }
  }
}

output "hook_ids" {
  description = "Hook IDs from the hook module."
  value       = module.hook.ids
}

output "environment_hook_ids" {
  description = "Environment hook link IDs from the environment_link module."
  value       = module.hook_environment_link.ids
}

output "environment_hooks" {
  description = "Full environment hook link objects from the environment_link module."
  value       = module.hook_environment_link.environment_hooks
}
