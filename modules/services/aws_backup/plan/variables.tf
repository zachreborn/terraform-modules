variable "name" {
  description = "The name of the backup plan."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the backup plan."
  type        = map(string)
}

variable "rules" {
  description = "A list of backup rules."
  type = list(object({
    rule_name                = string
    target_vault_name        = string
    schedule                 = string
    enable_continuous_backup = bool
    start_window             = number
    completion_window        = number
    delete_after             = number
  }))
}

variable "iam_role_arn" {
  description = "The ARN of the IAM role to use for backup selection."
  type        = string
}

variable "selection_name" {
  description = "The name of the backup selection."
  type        = string
}

variable "resources" {
  description = "A list of resources to include in the backup selection."
  type        = list(string)
  default = [
    "*"
  ]
}

variable "not_resources" {
  description = "A list of resources to exclude from the backup selection."
  type        = list(string)
  default = [
    "arn:aws:ec2:*:*:instance/*",
    "arn:aws:s3:*"
  ]
}

