variable "tags" {
  type        = map(any)
  description = "(Optional) A mapping of tags to assign to the resource."
  default = {
    "Name" = "ssm-service-role"
  }
}
