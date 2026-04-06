###########################
# Patch Group Outputs
###########################

output "id" {
  description = "The ID of the patch group association (format: patch_group,baseline_id)."
  value       = aws_ssm_patch_group.this.id
}

output "baseline_id" {
  description = "The ID of the associated patch baseline."
  value       = aws_ssm_patch_group.this.baseline_id
}

output "patch_group" {
  description = "The name of the patch group."
  value       = aws_ssm_patch_group.this.patch_group
}
