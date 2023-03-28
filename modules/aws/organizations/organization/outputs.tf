############################################################
# AWS Organization
############################################################
output "accounts" {
  description = "List of organization accounts.All elements have these attributes: arn, email, id, name, status."
  value = aws_organizations_organization.org.accounts
}

output "master_account_arn" {
  description = "ARN of the master account"
  value = aws_organizations_organization.org.master_account_arn
}

output "master_account_email" {
  description = "Email address of the master account"
  value = aws_organizations_organization.org.master_account_email
}

output "master_account_id" {
  description = "ID of the master account"
  value = aws_organizations_organization.org.master_account_id
}

output "arn" {
  description = "ARN of the organization"
  value = aws_organizations_organization.org.arn
}

output "id" {
  description = "ID of the organization"
  value = aws_organizations_organization.org.id
}

output "roots" {
  description = "List of organization roots.All elements have these attributes: arn, id, name, policy_types."
  value = aws_organizations_organization.org.roots
}
