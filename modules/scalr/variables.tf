###########################
# VCS Provider Variables
###########################
variable "vcs_provider_agent_pool_id" {
  description = "The Agent Pool ID to assign to the VCS Provider."
  type        = string
  default     = null
}

variable "vcs_provider_draft_pr_runs_enabled" {
  description = "Whether draft PR runs are enabled for the VCS Provider."
  type        = bool
  default     = false
}

variable "vcs_provider_environments" {
  description = "List of Scalr Environments which the VCS Provider will be shared to."
  type        = list(string)
  default     = ["*"]
}

variable "vcs_provider_token" {
  description = "The api key or personal access token for the VCS Provider."
  type        = string
  sensitive   = true
  default     = null
}

variable "vcs_provider_url" {
  description = "The URL of the VCS Provider. Required when using a self-hosted vcs provider."
  type        = string
  default     = null
}

variable "vcs_provider_username" {
  description = "The username for the VCS Provider. Required for 'bitbucket_enterprise'."
  type        = string
  default     = null
}

variable "vcs_provider_vcs_type" {
  description = "The type of VCS Provider. Valid values are 'github', 'github_enterprise', 'gitlab', 'gitlab_enterprise', and 'bitbucket_enterprise'."
  type        = string
  default     = "github"
  validation {
    condition     = contains(["github", "github_enterprise", "gitlab", "gitlab_enterprise", "bitbucket_enterprise"], var.vcs_provider_vcs_type)
    error_message = "The vcs_type must be one of 'github', 'github_enterprise', 'gitlab', 'gitlab_enterprise', or 'bitbucket_enterprise'."
  }
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

variable "aws_export_shell_variables" {
  description = "Whether to export provider credentials as shell variables when using the Scalr CLI with the aws provider configuration."
  type        = bool
  default     = false
}

variable "aws_external_id" {
  description = "The external ID to use when assuming the role. Required if aws_credentials_type is set to 'role_delegation' and the role requires an external ID."
  type        = string
  default     = null
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
  default     = null
  validation {
    condition     = contains(["aws_account", "aws_service"], var.aws_trusted_entity_type) || var.aws_trusted_entity_type == null
    error_message = "The aws_trusted_entity_type must be one of null, 'aws_account', or 'aws_service'."
  }
}

###########################
# AzureRM Provider Variables
###########################
variable "azurerm_audience" {
  description = "The value of the 'aud' claim for the identity token. Required if azurerm_auth_type is set to 'oidc'."
  type        = string
  default     = null
}

variable "azurerm_auth_type" {
  description = "Authentication type for the AzureRM provider configuration. Valid values are 'client-secrets' and 'oidc'."
  type        = string
  default     = "client-secrets"
  validation {
    condition     = contains(["client-secrets", "oidc"], var.azurerm_auth_type)
    error_message = "The azurerm_auth_type must be one of 'client-secrets' or 'oidc'."
  }
}

variable "azurerm_client_id" {
  description = "The Client ID that should be used for the AzureRM provider configuration."
  type        = string
  default     = null
}

variable "azurerm_client_secret" {
  description = "The Client Secret that should be used for the AzureRM provider configuration. Required when azurerm_auth_type is 'client-secrets'."
  type        = string
  sensitive   = true
  default     = null
}

variable "azurerm_environments" {
  description = "List of Scalr Environments which the AzureRM provider configuration will be shared to."
  type        = list(string)
  default     = null
}

variable "azurerm_export_shell_variables" {
  description = "Whether to export provider credentials as shell variables when using the Scalr CLI with the AzureRM provider configuration."
  type        = bool
  default     = false
}

variable "azurerm_owners" {
  description = "List of Scalr Team IDs who will own the AzureRM Provider Configuration."
  type        = list(string)
  default     = null
}

variable "azurerm_provider_config" {
  description = "YAML formatted file defining one or more AzureRM provider configurations."
  type        = string
  default     = null
}

variable "azurerm_subscription_id" {
  description = "The Subscription ID that should be used for the AzureRM provider configuration. If omitted, it must be set as a shell variable in the workspace or as part of the source configuration."
  type        = string
  default     = null
}

variable "azurerm_tag_ids" {
  description = "List of Tag IDs to assign to the AzureRM Provider Configuration."
  type        = list(string)
  default     = null
}

variable "azurerm_tenant_id" {
  description = "The Tenant ID that should be used for the AzureRM provider configuration."
  type        = string
  default     = null
}

###########################
# Google Provider Variables
###########################
variable "google_auth_type" {
  description = "Authentication type for the Google provider configuration. Valid values are 'service-account-key' and 'oidc'."
  type        = string
  default     = "service-account-key"
  validation {
    condition     = contains(["service-account-key", "oidc"], var.google_auth_type)
    error_message = "The google_auth_type must be one of 'service-account-key' or 'oidc'."
  }
}

variable "google_credentials" {
  description = "Service account key file in JSON format for the Google provider configuration. Required when google_auth_type is 'service-account-key'."
  type        = string
  sensitive   = true
  default     = null
}

variable "google_default_labels_labels" {
  description = "Default labels to be applied to all resources created by the Google provider configuration."
  type        = map(string)
  default     = null
}

variable "google_default_labels_strategy" {
  description = "On duplicate key behaviour for default labels. Valid values are 'skip' and 'update'."
  type        = string
  default     = null
  validation {
    condition     = var.google_default_labels_strategy == null || contains(["skip", "update"], var.google_default_labels_strategy)
    error_message = "The google_default_labels_strategy must be one of null, 'skip', or 'update'."
  }
}

variable "google_environments" {
  description = "List of Scalr Environments which the Google provider configuration will be shared to."
  type        = list(string)
  default     = null
}

variable "google_export_shell_variables" {
  description = "Whether to export provider credentials as shell variables when using the Scalr CLI with the Google provider configuration."
  type        = bool
  default     = false
}

variable "google_owners" {
  description = "List of Scalr Team IDs who will own the Google Provider Configuration."
  type        = list(string)
  default     = null
}

variable "google_project" {
  description = "The default Google Cloud project ID to manage resources in. If another project ID is specified on a resource, it will take precedence."
  type        = string
  default     = null
}

variable "google_provider_config" {
  description = "YAML formatted file defining one or more Google provider configurations."
  type        = string
  default     = null
}

variable "google_service_account_email" {
  description = "The service account email used to authenticate to GCP. Required when google_auth_type is 'oidc'."
  type        = string
  default     = null
}

variable "google_tag_ids" {
  description = "List of Tag IDs to assign to the Google Provider Configuration."
  type        = list(string)
  default     = null
}

variable "google_use_default_project" {
  description = "Whether the project a credential is created in will be used by default."
  type        = bool
  default     = null
}

variable "google_workload_provider_name" {
  description = "The canonical name of the workload identity provider. Required when google_auth_type is 'oidc'."
  type        = string
  default     = null
}

###########################
# Custom Provider Variables
###########################
variable "custom_argument" {
  description = "List of argument blocks defining the configuration for a custom provider. Each argument requires a 'name' and may include 'value', 'description', 'hcl', and 'sensitive'. Can be overridden per provider configuration in the YAML file. When an argument's 'sensitive' is true, its 'value' here is ignored -- supply the real value via var.custom_argument_secrets instead."
  type = list(object({
    name        = string
    value       = optional(string)
    description = optional(string)
    hcl         = optional(bool, false)
    sensitive   = optional(bool, false)
  }))
  default = []
}

variable "custom_argument_secrets" {
  description = <<-EOT
    Map of sensitive custom provider argument values, keyed by the provider configuration's name
    (a top-level key in custom_provider_config, or the resource's own name for module-wide
    defaults) and then by argument name. Populate an entry here instead of setting 'value' directly
    in custom_argument or the YAML file whenever an argument sets 'sensitive = true': the
    provider's sensitive flag only controls masking in Scalr and does not prevent the value from
    appearing in Terraform/OpenTofu plan output when sourced from a non-sensitive variable.

    Example:
      custom_argument_secrets = {
        kubernetes = {
          password = "<value-from-a-secret-manager>"
        }
      }
  EOT
  type        = map(map(string))
  sensitive   = true
  default     = {}
}

variable "custom_environments" {
  description = "List of Scalr Environments which the custom provider configuration will be shared to."
  type        = list(string)
  default     = null
}

variable "custom_export_shell_variables" {
  description = "Whether to export provider credentials as shell variables when using the Scalr CLI with the custom provider configuration."
  type        = bool
  default     = false
}

variable "custom_owners" {
  description = "List of Scalr Team IDs who will own the custom Provider Configuration."
  type        = list(string)
  default     = null
}

variable "custom_provider_config" {
  description = "YAML formatted file defining one or more custom provider configurations."
  type        = string
  default     = null
}

variable "custom_provider_name" {
  description = "The name of the Terraform provider being configured (e.g. 'kubernetes'). Can be overridden per provider configuration in the YAML file."
  type        = string
  default     = null
}

variable "custom_tag_ids" {
  description = "List of Tag IDs to assign to the custom Provider Configuration."
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
variable "aws_provider_config" {
  description = "YAML formatted file defining one or more AWS provider configurations."
  type        = string
  default     = null
}

variable "scalr_config" {
  description = "YAML formatted file defining Scalr environments and their workspaces."
  type        = string
}

variable "vcs_provider_config" {
  description = "YAML formatted file defining one or more VCS provider configurations."
  type        = string
  default     = null
}

variable "vcs_provider_id" {
  description = "The VCS Provider ID to use for the workspace. Can be overridden per workspace in the YAML file."
  type        = string
  default     = null
}
