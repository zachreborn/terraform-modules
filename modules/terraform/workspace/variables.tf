##############################
# Terraform Workspace Variables
##############################

variable "agent_pool_id" {
  type        = string
  description = "(Optional) The ID of an agent pool to assign to the workspace. Requires execution_mode to be set to agent. This value must not be provided if execution_mode is set to any other value or if operations is provided."
  default     = null
}

variable "allow_destroy_plan" {
  type        = bool
  description = "(Optional) Whether destroy plans can be queued on the workspace."
  default     = false
  validation {
    condition     = can(regex("true|false", var.allow_destroy_plan))
    error_message = "allow_destroy_plan must be true or false."
  }
}

variable "auto_apply" {
  type        = bool
  description = "(Optional) Whether to automatically apply changes when a Terraform plan is successful. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("true|false", var.auto_apply))
    error_message = "auto_apply must be true or false."
  }
}

variable "assessments_enabled" {
  type        = bool
  description = "(Optional) Whether to regularly run health assessments such as drift detection on the workspace. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("true|false", var.assessments_enabled))
    error_message = "assessments_enabled must be true or false."
  }
}

variable "description" {
  type        = string
  description = "(Optional) A description for the workspace."
  default     = null
}

variable "execution_mode" {
  type        = string
  description = "(Optional) Which execution mode to use. Using Terraform Cloud, valid values are remote, local or agent. Defaults to remote. Using Terraform Enterprise, only remote and local execution modes are valid. When set to local, the workspace will be used for state storage only. This value must not be provided if operations is provided."
  default     = "remote"
  validation {
    condition     = can(regex("remote|local|agent", var.execution_mode))
    error_message = "execution_mode must be remote, local or agent."
  }
}

variable "file_triggers_enabled" {
  type        = bool
  description = "(Optional) Whether to filter runs based on the changed files in a VCS push. Defaults to false. If enabled, the working directory and trigger prefixes describe a set of paths which must contain changes for a VCS push to trigger a run. If disabled, any push will trigger a run."
  default     = false
  validation {
    condition     = can(regex("true|false", var.file_triggers_enabled))
    error_message = "file_triggers_enabled must be true or false."
  }
}

variable "global_remote_state" {
  type        = bool
  description = "(Optional) Whether the workspace allows all workspaces in the organization to access its state data during runs. If false, then only specifically approved workspaces can access its state (remote_state_consumer_ids)."
  default     = false
  validation {
    condition     = can(regex("true|false", var.global_remote_state))
    error_message = "global_remote_state must be true or false."
  }
}

variable "name" {
  type        = string
  description = "(Required) Name of the workspace."
}

variable "organization" {
  type        = string
  description = "(Required) Name of the organization."
}

variable "queue_all_runs" {
  type        = bool
  description = "(Optional) Whether the workspace should start automatically performing runs immediately after its creation. Defaults to true. When set to false, runs triggered by a webhook (such as a commit in VCS) will not be queued until at least one run has been manually queued. Note: This default differs from the Terraform Cloud API default, which is false. The provider uses true as any workspace provisioned with false would need to then have a run manually queued out-of-band before accepting webhooks."
  default     = true
  validation {
    condition     = can(regex("true|false", var.queue_all_runs))
    error_message = "queue_all_runs must be true or false."
  }
}

variable "remote_state_consumer_ids" {
  type        = list(string)
  description = "(Optional) The set of workspace IDs set as explicit remote state consumers for the given workspace."
  default     = null
}

variable "speculative_enabled" {
  type        = bool
  description = "(Optional) Whether this workspace allows speculative plans. Defaults to true. Setting this to false prevents Terraform Cloud or the Terraform Enterprise instance from running plans on pull requests, which can improve security if the VCS repository is public or includes untrusted contributors."
  default     = true
  validation {
    condition     = can(regex("true|false", var.speculative_enabled))
    error_message = "speculative_enabled must be true or false."
  }
}

variable "ssh_key_id" {
  type        = string
  description = "(Optional) The ID of an SSH key to assign to the workspace."
  default     = null
}

variable "structured_run_output_enabled" {
  type        = bool
  description = "(Optional) Whether this workspace should show output from Terraform runs using the enhanced UI when available. Defaults to true. Setting this to false ensures that all runs in this workspace will display their output as text logs."
  default     = true
  validation {
    condition     = can(regex("true|false", var.structured_run_output_enabled))
    error_message = "structured_run_output_enabled must be true or false."
  }
}

variable "terraform_version" {
  type        = string
  description = "(Optional) The version of Terraform to use for this workspace. This can be either an exact version or a version constraint (like ~> 1.0.0); if you specify a constraint, the workspace will always use the newest release that meets that constraint. Defaults to the latest available version."
  default     = "~>1.4.0"
}

variable "trigger_prefixes" {
  type        = list(string)
  description = "(Optional) List of repository-root-relative paths which describe all locations to be tracked for changes."
  default     = null
}

variable "tag_names" {
  type        = list(string)
  description = "(Optional) A list of tag names for this workspace. Note that tags must only contain letters, numbers or colons."
  default     = null
}

variable "working_directory" {
  type        = string
  description = "(Optional) A relative path that Terraform will execute within. Defaults to the root of your repository."
  default     = null
}

variable "identifier" {
  type        = string
  description = "(Required) A reference to your VCS repository in the format <organization>/<repository> where <organization> and <repository> refer to the organization and repository in your VCS provider. The format for Azure DevOps is //_git/."
}

variable "branch" {
  type        = string
  description = "(Optional) The repository branch that Terraform will execute from. This defaults to the repository's default branch (e.g. main)."
  default     = null
}

variable "ingress_submodules" {
  type        = bool
  description = "(Optional) Whether submodules should be fetched when cloning the VCS repository. Defaults to false."
  default     = false
}

variable "oauth_token_id" {
  type        = string
  description = "(Required) The VCS Connection (OAuth Connection + Token) to use. This ID can be obtained from a tfe_oauth_client resource."
}

##############################
# Terraform Team Access/Permissions
##############################

variable "permission_map" {
  type        = map(any)
  description = "(Required) The permissions map which maps the team_id to the permission access level. Exampe: 'terraform_all_admin = {id = team-fdsa5122q6rwYXP, access = admin}'"
}

##############################
# Variables Variables
##############################

variable "enable_dynamic_credentials" {
  type        = bool
  description = "(Optional) Whether to enable dynamic credentials for this workspace. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("true|false", var.enable_dynamic_credentials))
    error_message = "enable_dynamic_credentials must be true or false."
  }
}

variable "dynamic_role_arn" {
  type        = string
  description = "(Optional) The ARN of the IAM role to assume when generating dynamic credentials for this workspace. This is only required if enable_dynamic_credentials is true."
  default     = null
}
