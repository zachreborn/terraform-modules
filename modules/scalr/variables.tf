###########################
# Scalr Provider Variables
###########################

variable "scalr_environments" {
  description = "List of Scalr Environments which the provider will be shared to."
  type        = list(string)
  default     = null
}

variable "scalr_hostname" {
  description = "The Scalr hostname."
  type        = string
}

variable "scalr_provider_name" {
  description = "Name of the Scalr Provider Configuration."
  type        = string
  default     = "scalr"
}

variable "scalr_owners" {
  description = "List of Scalr User IDs who will own the Provider Configuration."
  type        = list(string)
  default     = []
}

variable "scalr_token" {
  description = "The Scalr API token."
  type        = string
  sensitive   = true
}

###########################
# AWS Provider Variables
###########################
variable "aws_access_key" {
  description = "The AWS access key."
  type        = string
  sensitive   = true
  default     = null
}

variable "aws_account_type" {
  description = "The type of AWS account. Valid values are 'regular', 'gov-cloud', and 'cn-cloud'."
  type        = string
  default     = "regular"
  validation {
    condition     = contains(["regular", "gov-cloud", "cn-cloud"], var.aws_account_type)
    error_message = "The aws_account_type must be one of 'regular', 'gov-cloud', or 'cn-cloud'."
  }
}

variable "aws_audience" {
  description = "The audience for the AWS credentials. Required if credentials_type is set to 'oidc'."
  type        = string
  default     = null
}

variable "aws_credentials_type" {
  description = "The type of AWS credentials. Valid values are 'access_keys', 'oidc', and 'role_delegation'."
  type        = string
  default     = "oidc"
  validation {
    condition     = contains(["access_keys", "oidc", "role_delegation"], var.aws_credentials_type)
    error_message = "The aws_credentials_type must be one of 'access_keys', 'oidc', or 'role_delegation'."
  }
}

variable "aws_environments" {
  description = "List of Scalr Environments which the provider will be shared to."
  type        = list(string)
  default     = null
}

variable "aws_external_id" {
  description = "The external ID to use when assuming the role. Required if aws_credentials_type is set to 'role_delegation' and the role requires an external ID."
  type        = string
  default     = null
}

variable "aws_provider_name" {
  description = "Name of the AWS Provider Configuration."
  type        = string
  default     = "aws"
}

variable "aws_owners" {
  description = "List of Scalr User IDs who will own the Provider Configuration."
  type        = list(string)
  default     = null
}

variable "aws_role_arn" {
  description = "The ARN of the role to assume. Required if aws_credentials_type is set to 'oidc' or 'role_delegation'."
  type        = string
  default     = null
}

variable "aws_secret_key" {
  description = "The AWS secret key."
  type        = string
  sensitive   = true
  default     = null
}

variable "aws_trusted_entity_type" {
  description = "The type of trusted entity for the role. Valid values are 'aws_account' and 'aws_service'."
  type        = string
  default     = "aws_account"
  validation {
    condition     = contains(["aws_account", "aws_service"], var.aws_trusted_entity_type)
    error_message = "The aws_trusted_entity_type must be one of 'aws_account' or 'aws_service'."
  }
}

###########################
# Provider Default Variables
###########################
variable "default_environment_ids" {
  description = "List of Environment IDs to set the default Provider Configurations in."
  type        = list(string)
  default     = null
}

###########################
# Environment Variables
###########################
variable "environment_default_provider_configurations" {
  description = "List of Provider Configuration IDs to set as the default in the Environment."
  type        = list(string)
  default     = null
}

variable "environment_default_workspace_agent_pool_id" {
  description = "The default Agent Pool ID to assign to Workspaces in the Environment."
  type        = string
  default     = null
}

variable "environment_federated_environments" {
  description = "List of Environment IDs to federate with this Environment."
  type        = list(string)
  default     = null
}

variable "environment_mask_sensitive_output" {
  description = "Whether to mask sensitive output values in the Environment."
  type        = bool
  default     = true
}

variable "environment_remote_backend" {
  description = "Whether Scalr manages the remote backend configuration for the Environment."
  type        = bool
  default     = true
}

variable "environment_remote_backend_overridable" {
  description = "Whether Workspaces in the Environment can override the remote backend configuration."
  type        = bool
  default     = false
}

variable "environment_storage_profile_id" {
  description = "The Storage Profile ID to use for the Environment."
  type        = string
  default     = null
}

variable "environment_tag_ids" {
  description = "List of Tag IDs to assign to the Environment."
  type        = list(string)
  default     = null
}


###########################
# Workspace Variables
###########################
variable "workspace_agent_pool_id" {
  description = "The Agent Pool ID to assign to the Workspace. Can be overridden per workspace in the YAML file."
  type        = string
  default     = null
}

variable "workspace_auto_apply" {
  description = "Whether to automatically apply runs when they are queued. Can be overridden per workspace in the YAML file."
  type        = bool
  default     = false
}

variable "workspace_auto_queue_runs" {
  description = "Whether to automatically queue runs when a workspace's configuration changes. Can be overridden per workspace in the YAML file. Valid values are 'skip_first', 'always', 'never', and 'on_create_only'."
  type        = string
  default     = "always"
  validation {
    condition     = contains(["skip_first", "always", "never", "on_create_only"], var.workspace_auto_queue_runs)
    error_message = "The auto_queue_runs must be one of 'skip_first', 'always', 'never', or 'on_create_only'."
  }
}

variable "workspace_deletion_protection_enabled" {
  description = "Whether to enable deletion protection for the workspace. Can be overridden per workspace in the YAML file."
  type        = bool
  default     = true
}

variable "workspace_execution_mode" {
  description = "The execution mode for the workspace. Can be overridden per workspace in the YAML file. Valid values are 'remote' and 'local'."
  type        = string
  default     = "remote"
  validation {
    condition     = contains(["remote", "local"], var.workspace_execution_mode)
    error_message = "The execution_mode must be one of 'remote' or 'local'."
  }
}

variable "workspace_force_latest_run" {
  description = "Whether to force a new run to be created for the workspace. Can be overridden per workspace in the YAML file."
  type        = bool
  default     = false
}

variable "workspace_iac_platform" {
  description = "The Infrastructure as Code platform for the workspace. Valid values are 'terraform' or 'opentofu'."
  type        = string
  default     = "opentofu"
  validation {
    condition     = contains(["terraform", "opentofu"], var.workspace_iac_platform)
    error_message = "The iac_platform must be one of 'terraform' or 'opentofu'."
  }
}

variable "workspace_module_version_id" {
  description = "The Module Version ID to use for the workspace. Can be overridden per workspace in the YAML file. Must be in the format 'modver-<RANDOM STRING>'. This cannot be set when using a vcs repository as the source for the workspace."
  type        = string
  default     = null
}

variable "workspace_operations" {
  description = "Whether to enable remote execution for the workspace. When set to false, the workspace only stores its state. Can be overridden per workspace in the YAML file."
  type        = bool
  default     = true
}

variable "workspace_remote_backend" {
  description = "Whether Scalr manages the remote backend configuration. Can be overridden per workspace in the YAML file."
  type        = bool
  default     = true
}

variable "workspace_remote_state_consumers" {
  description = "List of Workspace IDs that can read the remote state of this workspace. Can be overridden per workspace in the YAML file."
  type        = list(string)
  default     = null
}

variable "workspace_run_operation_timeout" {
  description = "The maximum time, in minutes, that a run operation (plan or apply) can take before it is automatically canceled. Can be overridden per workspace in the YAML file."
  type        = number
  default     = 60
}

variable "workspace_ssh_key_id" {
  description = "The SSH Key ID to use for the workspace. Can be overridden per workspace in the YAML file."
  type        = string
  default     = null
}

variable "workspace_tag_ids" {
  description = "List of Tag IDs to assign to the workspace. Can be overridden per workspace in the YAML file."
  type        = list(string)
  default     = null
}

variable "workspace_terraform_version" {
  description = "The opentofu or terraform version to use for the workspace. Can be overridden per workspace in the YAML file. Must be in the format 'X.Y.Z'."
  type        = string
  default     = null
}

variable "workspace_type" {
  description = "The type of workspace. Valid values are 'production', 'staging', 'testing', 'development', and 'unmapped'."
  type        = string
  default     = "production"
  validation {
    condition     = contains(["production", "staging", "testing", "development", "unmapped"], var.workspace_type)
    error_message = "The type must be one of 'production', 'staging', 'testing', 'development', or 'unmapped'."
  }
}

variable "workspace_var_files" {
  description = "A list of paths which hold the '.tfvars' files for the workspace. Can be overridden per workspace in the YAML file."
  type        = list(string)
  default     = []
}

variable "workspace_working_directory" {
  description = "The working directory as a relative path which opentofu or terraform will run for the workspace. Can be overridden per workspace in the YAML file."
  type        = string
  default     = null
}

###########################
# General Variables
###########################
variable "environments_config" {
  description = "YAML formatted file defining environments and their workspaces."
  type        = string
}

variable "export_shell_variables" {
  description = "Whether to export provider credentials as shell variables when using the Scalr CLI."
  type        = bool
  default     = false
}
