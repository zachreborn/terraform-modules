output "arn" {
  description = "Queue ARN."
  value       = aws_sqs_queue.queue.arn
}

output "id" {
  description = "Queue URL (legacy output)."
  value       = aws_sqs_queue.queue.id
}

output "url" {
  description = "Queue URL."
  value       = aws_sqs_queue.queue.url
}

output "name" {
  description = "Physical queue name."
  value       = aws_sqs_queue.queue.name
}

output "tags_all" {
  description = "Queue tags including provider default tags."
  value       = aws_sqs_queue.queue.tags_all
}

output "kms_key_arn" {
  description = "Created child key ARN; null when key creation is disabled."
  value       = var.create_kms_key ? module.kms[0].arn : null
}

output "kms_key_id" {
  description = "Created child key ID; null when key creation is disabled."
  value       = var.create_kms_key ? module.kms[0].key_id : null
}

output "effective_kms_master_key_id" {
  description = "Exact KMS reference passed to the queue, including external IDs or aliases."
  value       = local.effective_kms_master_key_id
}
