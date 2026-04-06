###########################
# Patch Group Variables
###########################

variable "baseline_id" {
  description = "(Required) The ID of the patch baseline to associate with the patch group."
  type        = string
}

variable "patch_group" {
  description = "(Required) The name of the patch group. Must exactly match the value of the 'Patch Group' tag applied to managed instances. Each patch group can only be associated with one baseline."
  type        = string
}
