output "mail" {
  description = "The SMTP address for the group."
  value       = azuread_group.this.mail
}

output "object_id" {
  description = "The object ID of the Azure AD group."
  value       = azuread_group.this.object_id
}

output "proxy_addresses" {
  description = "The proxy addresses for the group."
  value       = azuread_group.this.proxy_addresses
}
