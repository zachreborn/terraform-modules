output "arn" {
  description = "ARN of the cloudwatch log group used for flow logs"
  value       = aws_cloudwatch_log_group.log_group[*].id
}

output "flow_log_ids" {
  description = "IDs of the created aws_flow_log resources. Useful for callers to verify wiring (that the flow log count and its target IDs match what was passed in)."
  value       = aws_flow_log.this[*].id
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
