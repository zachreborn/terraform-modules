###########################
# Resource Variables
###########################

variable "name" {
  description = "(Required) The name of the capacity provider."
  type        = string
}

variable "auto_scaling_group_arn" {
  description = "(Required) The ARN of the existing EC2 Auto Scaling group to back the capacity provider."
  type        = string
}

variable "managed_draining" {
  description = "(Optional) Enables or disables a graceful shutdown of instances without disturbing workloads. Valid values are ENABLED and DISABLED."
  type        = string
  default     = "ENABLED"
}

variable "managed_termination_protection" {
  description = "(Optional) Enables or disables container-aware termination of instances in the Auto Scaling group when scale-in happens. Valid values are ENABLED and DISABLED. Defaults to ENABLED (AWS's own recommended secure default), but this requires managed_scaling to also be enabled (default) AND the target Auto Scaling group itself to already have instance scale-in protection (new_instances_protected_from_scale_in) enabled -- this module does not create or manage that Auto Scaling group, so set this to DISABLED if the supplied ASG does not have that protection configured."
  type        = string
  default     = "ENABLED"
}

variable "managed_scaling" {
  description = "(Optional) Configuration block defining the parameters of the Auto Scaling group capacity provider's managed scaling."
  type = object({
    status                    = optional(string, "ENABLED")
    target_capacity           = optional(number, 100)
    minimum_scaling_step_size = optional(number)
    maximum_scaling_step_size = optional(number)
    instance_warmup_period    = optional(number)
  })
  default = {}
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) A map of tags to assign to the capacity provider. A `Name` tag is merged automatically."
  type        = map(string)
  default     = {}
}
