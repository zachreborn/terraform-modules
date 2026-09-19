# Outputs
output "arn" {
  value = aws_kms_key.this.arn
}

output "key_id" {
  value = aws_kms_key.this.key_id
}

output "description" {
  value = aws_kms_key.this.description
}

output "deletion_window_in_days" {
  value = aws_kms_key.this.deletion_window_in_days
}

output "enable_key_rotation" {
  value = aws_kms_key.this.enable_key_rotation
}

output "alias_name_prefix" {
  value = aws_kms_alias.this.name_prefix
}
