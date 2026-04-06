###########################
# Patch Baseline Outputs
###########################

output "id" {
  description = "The ID of the patch baseline."
  value       = aws_ssm_patch_baseline.this.id
}

output "arn" {
  description = "The ARN of the patch baseline."
  value       = aws_ssm_patch_baseline.this.arn
}

output "name" {
  description = "The name of the patch baseline."
  value       = aws_ssm_patch_baseline.this.name
}

output "operating_system" {
  description = "The operating system family of the patch baseline."
  value       = aws_ssm_patch_baseline.this.operating_system
}

output "json" {
  description = "The JSON document describing the baseline's approval rules and filters."
  value       = aws_ssm_patch_baseline.this.json
}
