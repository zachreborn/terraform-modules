output "policy_arn" {
  description = "The ARN of the policy that was attached, resolved from either 'policy_arn' or the 'policy_name' lookup."
  value       = local.resolved_arn
}

output "id" {
  description = "The ID of the aws_iam_user_policy_attachment resource."
  value       = aws_iam_user_policy_attachment.this.id
}