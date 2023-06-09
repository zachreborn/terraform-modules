##############################
# Data Source Variables
##############################
variable "terraform_cloud_hostname" {
  type        = string
  description = "The hostname of the Terraform Cloud or Terraform Enterprise environment you'd like to use with the identity provider"
  default     = "app.terraform.io"
}

##############################
# AWS Identity Provider Variables
##############################
variable "iam_role_name" {
  type        = string
  description = "(Optional) The name of the IAM role to assume when generating dynamic credentials for this workspace."
  default     = "terraform_cloud"
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to the workspace."
  default = {
    environment = "prod"
    terraform   = "true"
  }
}

variable "terraform_cloud_aws_audience" {
  type        = string
  default     = "aws.workload.identity"
  description = "(Optional) The audience value to use in the terraform run identity tokens"
}

variable "terraform_cloud_organization" {
  type        = string
  description = "(Required) The name of the Terraform Cloud organization which the workspace is in."
}

variable "terraform_cloud_project_name" {
  type        = string
  description = "(Optional) The name of the Terraform Cloud project which the workspace is in."
  default     = "Default Project"
}

variable "terraform_cloud_workspace_name" {
  type        = string
  description = "(Optional) The name of the Terraform Cloud workspace which will use OIDC."
  default     = "*" # This is a wildcard to allow all workspaces to use this role
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_*]{0,255}$", var.terraform_cloud_workspace_name))
    error_message = "The workspace name must be 1-256 characters long, and may only contain letters, numbers, asterisks, underscores, and dashes."
  }
}

variable "terraform_role_policy_arn" {
  type        = string
  description = "(Optional) AWS IAM AdministratorAccess policy arn"
  default     = "arn:aws:iam::aws:policy/AdministratorAccess"
}
