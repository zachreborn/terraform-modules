variable "groups" {
  description = "(Required) The list of groups to create."
  type = map(object({
    display_name = string # (Required) The friendly name to identify the group.
    description  = string # (Optional) The description of the group.
  }))
  # Example
  # groups = {
  #   "Administrators" = {
  #     display_name = "Administrators"
  #     description  = "The group for the administrators of the application."
  #   },
  #   "Users" = {
  #     display_name = "Users"
  #     description  = "The group for the users of the application."
  #   }
  # }
}
