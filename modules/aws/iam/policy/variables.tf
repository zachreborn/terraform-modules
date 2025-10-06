##############################
# Policy Variables
##############################

variable "description" {
  type        = string
  description = "(Required) Description of the IAM policy. Changes to the description will force the creation of a new resource."
}

variable "name" {
  type        = string
  description = "(Required) The name used to generate a unique name of the policy."
}

variable "name_prefix" {
  type        = string
  description = "(Required) The prefix used to generate a unique name of the policy. If omitted, Terraform will assign a random, unique name. Changes to the name will force the creation of a new resource."
}

variable "path" {
  type        = string
  description = "(Optional) Path in which to create the policy. See IAM Identifiers for more information. Defaults to `/`."
  default     = "/"
}

variable "policy" {
  type        = string
  description = "(Required) The policy document. This is a JSON formatted string. The heredoc syntax, file function, or the aws_iam_policy_document data source are all helpful here."
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to the IAM policy."
  default = {
    terraform = "true"
  }
}
