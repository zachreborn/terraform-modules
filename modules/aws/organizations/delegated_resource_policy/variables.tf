############################################################
# AWS Organization Delegated Resource Policy Variables
############################################################

variable "content" {
  description = "(Required) The content of the AWS Organization's delegated resource policy in JSON format. This policy defines the permissions and actions that are allowed or denied for the delegated administrator."
  type        = string
  # Example:
  # content = jsonencode({
  #   Version = "2012-10-17",
  #   Statement = [
  #     {
  #       Effect = "Allow",
  #       Action = "organizations:DescribeOrganization",
  #       Resource = "*"
  #     }
  #   ]
  # })
}

############################################################
# General Variables
############################################################

variable "tags" {
  description = "(Optional) A map of tags to assign to the AWS Organization's delegated resource policy. Tags are key-value pairs that help organize and manage resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}
