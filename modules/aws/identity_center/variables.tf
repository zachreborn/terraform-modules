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

variable "users" {
  description = "(Required) The list of users to create."
  type = map(object({
    given_name   = string # (Required) The given name of the user.
    family_name  = string # (Required) The family name of the user.
    user_name    = string # (Required) The username of the user.

    honorific_prefix = optional(string) # (Optional) The honorific prefix of the user.
    honorific_suffix = optional(string) # (Optional) The honorific suffix of the user.
    middle_name      = optional(string) # (Optional) The middle name of the user.
    nickname         = optional(string) # (Optional) The nickname of the user.

    email                   = optional(string) # (Optional) The email address of the user.
    email_is_primary        = optional(bool)   # (Optional) Indicates whether the email address is the primary email address of the user.
    email_type              = optional(string) # (Optional) The type of the email address of the user.
    phone_number            = optional(string) # (Optional) The phone number of the user.
    phone_number_is_primary = optional(bool)   # (Optional) Indicates whether the phone number is the primary phone number of the user.
    phone_number_type       = optional(string) # (Optional) The type of the phone number of the user.

    preferred_language = optional(string) # (Optional) The user's preferred language.
    timezone           = optional(string) # (Optional) The user's time zone.
    title              = optional(string) # (Optional) The user's title.
    user_type          = optional(string) # (Optional) The type of the user.

    groups = optional(list(string)) # (Optional) The list of groups the user belongs to.
  }))
  # Example
  # users = {
  #   "John Hill" = {
  #     given_name       = "John"
  #     family_name      = "Hill"
  #     user_name        = "john.hill@example.com"
  #     email            = "john.hill@example.com"
  #     email_is_primary = "true"
  #     groups           = ["Administrators"]
  #   }
  # }
}
