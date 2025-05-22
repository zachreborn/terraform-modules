output "vault_name" {
  description = "The name of the backup vault."
  value       = aws_backup_vault.this.name
}

output "vault_arn" {
  description = "The ARN of the backup vault."
  value       = aws_backup_vault.this.arn
}

