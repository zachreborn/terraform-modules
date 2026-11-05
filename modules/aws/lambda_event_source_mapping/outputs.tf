output "id" {
  description = "Event source mapping identifier (UUID)."
  value       = aws_lambda_event_source_mapping.this.id
}

output "uuid" {
  description = "Event source mapping UUID, identical to id."
  value       = aws_lambda_event_source_mapping.this.uuid
}

output "arn" {
  description = "Event source mapping ARN."
  value       = aws_lambda_event_source_mapping.this.arn
}

output "function_arn" {
  description = "Resolved Lambda function ARN."
  value       = aws_lambda_event_source_mapping.this.function_arn
}

output "event_source_arn" {
  description = "Event source ARN; null for self-managed Kafka."
  value       = aws_lambda_event_source_mapping.this.event_source_arn
}

output "state" {
  description = "Provider-reported mapping state."
  value       = aws_lambda_event_source_mapping.this.state
}

output "state_transition_reason" {
  description = "Provider-reported reason for the last state transition."
  value       = aws_lambda_event_source_mapping.this.state_transition_reason
}

output "last_modified" {
  description = "Provider-reported last modification timestamp."
  value       = aws_lambda_event_source_mapping.this.last_modified
}

output "last_processing_result" {
  description = "Provider-reported last processing result, not a delivery guarantee."
  value       = aws_lambda_event_source_mapping.this.last_processing_result
}

output "tags_all" {
  description = "Mapping tags including provider default tags."
  value       = aws_lambda_event_source_mapping.this.tags_all
}

output "batch_size" {
  description = "Effective numeric batch size."
  value       = aws_lambda_event_source_mapping.this.batch_size
}

output "enabled" {
  description = "Effective boolean polling setting."
  value       = aws_lambda_event_source_mapping.this.enabled
}

output "function_response_types" {
  description = "Configured partial batch response types."
  value       = aws_lambda_event_source_mapping.this.function_response_types
}

output "maximum_batching_window_in_seconds" {
  description = "Configured integer batching window; null delegates to source defaults."
  value       = aws_lambda_event_source_mapping.this.maximum_batching_window_in_seconds
}