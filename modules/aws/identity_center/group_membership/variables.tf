variable "group_id" {
  description = "(Required) The identifier for a group in the Identity Store."
  type        = string
}

variable "users" {
  description = "(Required) A map of user names to their respective IDs."
  type        = map(string)
}