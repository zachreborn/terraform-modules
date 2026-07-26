###########################
# Resource Variables
###########################
variable "linkages" {
  description = <<-EOT
    Map of scalr_policy_group_linkage resources to create, keyed by a caller-chosen logical name.
    Fields:
      - policy_group_id: (Required) ID of the policy group, in the format "pgrp-<RANDOM STRING>".
      - environment_id:  (Required) ID of the environment, in the format "env-<RANDOM STRING>".
  EOT
  type = map(object({
    policy_group_id = string
    environment_id  = string
  }))
  default = {}
}
