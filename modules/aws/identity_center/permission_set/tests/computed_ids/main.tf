###########################################################
# Harness module proving the permission_set module plans when
# BOTH the group ID and the account ID are known only after apply
# -- e.g. a newly created aws_identitystore_group and a newly
# created aws_organizations_account in the same apply (issues #121
# and #456). terraform_data.id is unknown at plan time, standing in
# for those computed IDs. Mirrors the harness pattern in
# modules/scalr/hook/tests/wiring.
###########################################################

terraform {
  required_version = ">= 1.4.0" # terraform_data
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "terraform_data" "new_group" {
  input = "new-group"
}

resource "terraform_data" "new_account" {
  input = "new-account"
}

module "permission_set" {
  source = "../.."

  name            = "ComputedIds"
  group_ids       = { new_group = terraform_data.new_group.id }
  target_accounts = { new_account = terraform_data.new_account.id }
}

output "assignment_ids" {
  description = "assignment_ids output of the permission_set module."
  value       = module.permission_set.assignment_ids
}

output "group_ids" {
  description = "group_ids output of the permission_set module."
  value       = module.permission_set.group_ids
}
