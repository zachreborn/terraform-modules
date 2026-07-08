############################################################
# AWS CloudTrail Organization Delegated Administrator
############################################################

output "account_id" {
  description = "The AWS account ID registered as the CloudTrail delegated administrator."
  value       = aws_cloudtrail_organization_delegated_admin_account.this.account_id
}

output "arn" {
  description = "The ARN of the delegated administrator's account."
  value       = aws_cloudtrail_organization_delegated_admin_account.this.arn
}

output "email" {
  description = "The email address associated with the delegated administrator's account."
  value       = aws_cloudtrail_organization_delegated_admin_account.this.email
}

output "name" {
  description = "The friendly name of the delegated administrator's account."
  value       = aws_cloudtrail_organization_delegated_admin_account.this.name
}

output "service_principal" {
  description = "The AWS CloudTrail service principal name."
  value       = aws_cloudtrail_organization_delegated_admin_account.this.service_principal
}
