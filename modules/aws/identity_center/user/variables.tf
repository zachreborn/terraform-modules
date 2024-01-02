variable "users" {
  description = "(Required) The list of users to create."
  type = map(object({
    display_name = string # (Required) The friendly name to identify the user.
    given_name   = string # (Required) The given name of the user.
    family_name  = string # (Required) The family name of the user.
    user_name    = string # (Required) The username of the user.

    honorific_prefix = optional(string) # (Optional) The honorific prefix of the user.
    honorific_suffix = optional(string) # (Optional) The honorific suffix of the user.
    middle_name      = optional(string) # (Optional) The middle name of the user.
    nickname         = optional(string) # (Optional) The nickname of the user.

    email        = optional(string) # (Optional) The email address of the user.
    phone_number = optional(string) # (Optional) The phone number of the user.

    preferred_language = optional(string) # (Optional) The user's preferred language.
    timezone           = optional(string) # (Optional) The user's time zone.
    title              = optional(string) # (Optional) The user's title.
    user_type          = optional(string) # (Optional) The type of the user.
  }))
  # Example
  # users = {
  #   "John Hill" = {
  #     display_name = "John Hill"
  #     given_name   = "John"
  #     family_name  = "Hill"
  #     user_name    = "John Hill"
  #     email        = "john.hill@example.com"
  #   }
  # }
}
