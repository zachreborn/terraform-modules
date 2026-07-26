###########################
# Scalr Workspace Var Set Link
###########################

variable "workspace_var_set_links" {
  description = <<-EOT
    (Required) Map of workspace <-> variable set links (`scalr_workspace_var_set`) to create, keyed by a
    caller-chosen logical name.
    Fields:
      - workspace_id: (Required) ID of the workspace, in the format `ws-<RANDOM STRING>`.
      - var_set_id:   (Required) ID of the variable set, in the format `varset-<RANDOM STRING>`.
  EOT
  type = map(object({
    workspace_id = string
    var_set_id   = string
  }))
  default = {}
}
