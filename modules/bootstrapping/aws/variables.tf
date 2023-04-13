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
variable "terraform_cloud_aws_audience" {
  type        = string
  default     = "aws.workload.identity"
  description = "The audience value to use in the terraform run identity tokens"
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to the workspace."
  default = {
    terraform = "true"
  }
}

variable "iam_role_name" {
  type        = string
  description = "(Optional) The name of the IAM role to assume when generating dynamic credentials for this workspace. This is only required if enable_aws is true."
  default     = "terraform_cloud"
}

variable "terraform_cloud_project_name" {
  type        = string
  description = "(Optional) The name of the Terraform Cloud project which the workspace is in. This is only required if enable_aws is true."
  default     = "Default Project"
}

variable "terraform_role_policy_arn" {
  type        = string
  description = "AWS IAM AdministratorAccess policy arn"
  default     = "arn:aws:iam::aws:policy/AdministratorAccess"
}
