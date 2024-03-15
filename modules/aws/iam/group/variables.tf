##############################
# Group Variables
##############################
variable "groups" {
  type = map(object({
    policy_arns = set(string)
  }))
  description = "(Required) - A map of groups to create. The key is the name of the group, and the value is a map of the group configuration."
  # Example:
  # groups = {
  #   group1 = {
  #     policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AmazonEC2FullAccess"]
  #   },
  #   group2 = {
  #     policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
  #   }
  # }
}

##############################
# Policy Attachment Variables
##############################
variable "policy_arns" {
  type        = set(string)
  description = "(Required) - A list of ARNs of the policies which you want attached to the groups."
}
