###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr account allowed-IP resource IDs (equal to the account ID) keyed by the same logical name used in var.account_allowed_ips."
  value       = { for key, value in scalr_account_allowed_ips.this : key => value.id }
}

output "account_allowed_ips" {
  description = "Map of full scalr_account_allowed_ips resource objects keyed by the same logical name used in var.account_allowed_ips."
  value       = { for key, value in scalr_account_allowed_ips.this : key => value }
}
