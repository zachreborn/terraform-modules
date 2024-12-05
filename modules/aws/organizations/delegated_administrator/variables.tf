############################################################
# AWS Organization Delegated Administrator
############################################################

variable "delegated_administrators" {
  description = "(Required) Map where the keys are AWS account IDs and the value is the service principal name to associate with the account. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com."
  type        = map(string)
  # Example:
  # delegated_administrators = {
  #   "123456789012" = "service-abbreviation.amazonaws.com",
  #   "123456789013" = "service-abbreviation.amazonaws.com"
  # }
}

############################################################
# General Variables
############################################################
