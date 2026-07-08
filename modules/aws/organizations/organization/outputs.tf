############################################################
# AWS Organization
############################################################
output "accounts" {
  description = "List of organization accounts.All elements have these attributes: arn, email, id, name, status."
  value       = aws_organizations_organization.org.accounts
}

output "master_account_arn" {
  description = "ARN of the master account"
  value       = aws_organizations_organization.org.master_account_arn
}

output "master_account_email" {
  description = "Email address of the master account"
  value       = aws_organizations_organization.org.master_account_email
}

output "master_account_id" {
  description = "ID of the master account"
  value       = aws_organizations_organization.org.master_account_id
}

output "arn" {
  description = "ARN of the organization"
  value       = aws_organizations_organization.org.arn
}

output "id" {
  description = "ID of the organization"
  value       = aws_organizations_organization.org.id
}

output "roots" {
  description = "List of organization roots.All elements have these attributes: arn, id, name, policy_types."
  value       = aws_organizations_organization.org.roots
}

############################################################
# Identity Center Service Control Policy
############################################################

output "identity_center_scp_id" {
  description = "ID of the Identity Center deny SCP, or null when enable_identity_center_scp is false."
  value       = try(module.identity_center_scp["identity_center_scp"].id, null)
}

output "identity_center_scp_arn" {
  description = "ARN of the Identity Center deny SCP, or null when enable_identity_center_scp is false."
  value       = try(module.identity_center_scp["identity_center_scp"].arn, null)
}

output "identity_center_scp_attachment_target_ids" {
  description = "List of target IDs the Identity Center deny SCP was attached to. Empty when attachment is disabled."
  value       = [for attachment in aws_organizations_policy_attachment.identity_center_scp : attachment.target_id]
}

############################################################
# Region Restriction Service Control Policy
############################################################

output "region_scp_id" {
  description = "ID of the Region-deny SCP, or null when enable_region_scp is false."
  value       = try(module.region_scp["region_scp"].id, null)
}

output "region_scp_arn" {
  description = "ARN of the Region-deny SCP, or null when enable_region_scp is false."
  value       = try(module.region_scp["region_scp"].arn, null)
}

output "region_scp_attachment_target_ids" {
  description = "List of target IDs the Region-deny SCP was attached to. Empty when attachment or creation is disabled."
  value       = [for attachment in aws_organizations_policy_attachment.region_scp : attachment.target_id]
}
