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

############################################################
# Deny Leave Organization Service Control Policy
############################################################

output "leave_organization_scp_id" {
  description = "ID of the Deny Leave Organization SCP, or null when enable_leave_organization_scp is false."
  value       = try(module.leave_organization_scp["leave_organization_scp"].id, null)
}

output "leave_organization_scp_arn" {
  description = "ARN of the Deny Leave Organization SCP, or null when enable_leave_organization_scp is false."
  value       = try(module.leave_organization_scp["leave_organization_scp"].arn, null)
}

output "leave_organization_scp_attachment_target_ids" {
  description = "List of target IDs the Deny Leave Organization SCP was attached to. Empty when attachment is disabled."
  value       = [for attachment in aws_organizations_policy_attachment.leave_organization_scp : attachment.target_id]
}

############################################################
# Deny Root Access Key Creation Service Control Policy
############################################################

output "root_access_key_scp_id" {
  description = "ID of the Deny Root Access Key Creation SCP, or null when enable_root_access_key_scp is false."
  value       = try(module.root_access_key_scp["root_access_key_scp"].id, null)
}

output "root_access_key_scp_arn" {
  description = "ARN of the Deny Root Access Key Creation SCP, or null when enable_root_access_key_scp is false."
  value       = try(module.root_access_key_scp["root_access_key_scp"].arn, null)
}

output "root_access_key_scp_attachment_target_ids" {
  description = "List of target IDs the Deny Root Access Key Creation SCP was attached to. Empty when attachment is disabled."
  value       = [for attachment in aws_organizations_policy_attachment.root_access_key_scp : attachment.target_id]
}

############################################################
# Deny Security Service Tampering Service Control Policy
############################################################

output "security_services_scp_id" {
  description = "ID of the Deny Security Service Tampering SCP, or null when enable_security_services_scp is false."
  value       = try(module.security_services_scp["security_services_scp"].id, null)
}

output "security_services_scp_arn" {
  description = "ARN of the Deny Security Service Tampering SCP, or null when enable_security_services_scp is false."
  value       = try(module.security_services_scp["security_services_scp"].arn, null)
}

output "security_services_scp_attachment_target_ids" {
  description = "List of target IDs the Deny Security Service Tampering SCP was attached to. Empty when attachment or creation is disabled."
  value       = [for attachment in aws_organizations_policy_attachment.security_services_scp : attachment.target_id]
}

############################################################
# Deny Root User Actions Service Control Policy
############################################################

output "root_actions_scp_id" {
  description = "ID of the Deny Root User Actions SCP, or null when enable_root_actions_scp is false."
  value       = try(module.root_actions_scp["root_actions_scp"].id, null)
}

output "root_actions_scp_arn" {
  description = "ARN of the Deny Root User Actions SCP, or null when enable_root_actions_scp is false."
  value       = try(module.root_actions_scp["root_actions_scp"].arn, null)
}

output "root_actions_scp_attachment_target_ids" {
  description = "List of target IDs the Deny Root User Actions SCP was attached to. Empty when attachment or creation is disabled."
  value       = [for attachment in aws_organizations_policy_attachment.root_actions_scp : attachment.target_id]
}
