output "arn" {
  description = "ARN of the cloudwatch log group used for flow logs"
  value       = aws_cloudwatch_log_group.log_group[*].arn
}

output "flow_log_ids" {
  description = "IDs of the created aws_flow_log resources. Useful for callers to verify wiring (that the flow log count and its target IDs match what was passed in)."
  value       = aws_flow_log.this[*].id
}

output "flow_log_eni_ids" {
  description = "eni_id of each created aws_flow_log resource, in the same order as flow_eni_ids. Null entries indicate the flow log was targeted at a different resource type."
  value       = aws_flow_log.this[*].eni_id
}

output "flow_log_subnet_ids" {
  description = "subnet_id of each created aws_flow_log resource, in the same order as flow_subnet_ids. Null entries indicate the flow log was targeted at a different resource type."
  value       = aws_flow_log.this[*].subnet_id
}

output "flow_log_vpc_ids" {
  description = "vpc_id of each created aws_flow_log resource, in the same order as flow_vpc_ids. Null entries indicate the flow log was targeted at a different resource type."
  value       = aws_flow_log.this[*].vpc_id
}

output "flow_log_transit_gateway_ids" {
  description = "transit_gateway_id of each created aws_flow_log resource, in the same order as flow_transit_gateway_ids. Null entries indicate the flow log was targeted at a different resource type."
  value       = aws_flow_log.this[*].transit_gateway_id
}

output "flow_log_transit_gateway_attachment_ids" {
  description = "transit_gateway_attachment_id of each created aws_flow_log resource, in the same order as flow_transit_gateway_attachment_ids. Null entries indicate the flow log was targeted at a different resource type."
  value       = aws_flow_log.this[*].transit_gateway_attachment_id
}

# The following outputs exist primarily so callers (and this module's own
# wrapper modules, e.g. modules/aws/vpc) can write native-test assertions
# proving their pass-through variables actually reach these resources,
# rather than only proving a plan succeeds. Native tests can only reach a
# child module's own outputs, not its internal resources directly.
output "kms_key_description" {
  description = "The description of the flow logs KMS key, proving key_description was forwarded."
  value       = aws_kms_key.key.description
}

output "iam_policy_description" {
  description = "The description of the flow logs IAM policy, proving iam_policy_description was forwarded."
  value       = aws_iam_policy.policy.description
}

output "iam_role_max_session_duration" {
  description = "The max_session_duration of the flow logs IAM role, proving iam_role_max_session_duration was forwarded."
  value       = aws_iam_role.role.max_session_duration
}

output "cloudwatch_log_group_deletion_protection_enabled" {
  description = "Whether deletion protection is enabled on the flow logs CloudWatch log group, proving cloudwatch_deletion_protection_enabled was forwarded."
  value       = aws_cloudwatch_log_group.log_group.deletion_protection_enabled
}
