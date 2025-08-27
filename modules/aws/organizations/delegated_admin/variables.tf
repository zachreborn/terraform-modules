############################################################
# AWS Organization Delegated Administrator
############################################################

variable "delegated_admins" {
  description = "(Required) Map where the keys are AWS account IDs and the values are lists of service principal names to associate with the account. This allows multiple service principals per account."
  type        = map(list(string))
  # Example:
  # delegated_admins = {
  #   "123456789012" = ["service1.amazonaws.com", "service2.amazonaws.com"],
  #   "123456789013" = ["service3.amazonaws.com"]
  # }
}

############################################################
# General Variables
############################################################
