###########################
# Resource Variables
###########################
variable "hooks" {
  description = <<-EOT
    Map of Scalr hooks keyed by a caller-supplied logical name. Each entry manages one
    `scalr_hook` resource, which allows custom scripts to run at different stages of the
    OpenTofu/Terraform workflow once linked to an environment via the companion
    `hook/environment_link` submodule.

    Fields:
      - name:            (Required) Name of the hook.
      - interpreter:      (Required) The interpreter to execute the hook script, e.g. "bash", "python3".
      - scriptfile_path:  (Required) Path to the script file in the VCS repository.
      - vcs_provider_id:  (Required) ID of the VCS provider, in the format "vcs-<RANDOM STRING>".
      - description:      (Optional) Description of the hook.
      - vcs_repo:          (Required) Source configuration of the VCS repository. Although the
                           published provider docs list this block as optional, the released
                           provider (>= 3.17.0) enforces it as required via a schema validator;
                           omitting it fails with "Block vcs_repo must have a configuration value
                           as the provider has marked it as required".
          - identifier: (Required) The identifier of the VCS repository, in the format ":org/:repo".
          - branch:     (Optional) Repository branch name.

    Example:
      hooks = {
        pre_apply_notify = {
          name            = "pre-apply-notify"
          interpreter     = "bash"
          scriptfile_path = "hooks/notify.sh"
          vcs_provider_id = "vcs-xxxxxxxxxx"
          vcs_repo = {
            identifier = "my-org/my-hooks-repo"
            branch     = "main"
          }
        }
      }
  EOT
  type = map(object({
    name            = string
    interpreter     = string
    scriptfile_path = string
    vcs_provider_id = string
    description     = optional(string)
    vcs_repo = object({
      identifier = string
      branch     = optional(string)
    })
  }))
  default  = {}
  nullable = false
}
