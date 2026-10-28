###########################
# Outputs
###########################
output "table_names" {
  description = "Physical table names keyed by logical identity."
  value       = tomap({ for k, t in aws_dynamodb_table.this : k => t.name })
}
output "table_ids" {
  description = "Provider table identifiers keyed by logical identity."
  value       = tomap({ for k, t in aws_dynamodb_table.this : k => t.id })
}
output "table_arns" {
  description = "Table ARNs keyed by logical identity."
  value       = tomap({ for k, t in aws_dynamodb_table.this : k => t.arn })
}
output "stream_arns" {
  description = "Stream ARNs keyed by logical identity; null when streams are disabled."
  value       = tomap({ for k, t in aws_dynamodb_table.this : k => t.stream_enabled ? t.stream_arn : null })
}
output "stream_labels" {
  description = "Stream labels keyed by logical identity; null when streams are disabled."
  value       = tomap({ for k, t in aws_dynamodb_table.this : k => t.stream_enabled ? t.stream_label : null })
}
output "tags_all" {
  description = "Effective provider and caller tags keyed by logical identity."
  value       = tomap({ for k, t in aws_dynamodb_table.this : k => t.tags_all })
}
output "replicas" {
  description = "Replica computed metadata keyed by table then replica region; empty stream fields are null."
  value = tomap({ for k, t in aws_dynamodb_table.this : k => tomap({ for r in t.replica : r.region_name => {
    arn          = r.arn
    stream_arn   = r.stream_arn == "" ? null : r.stream_arn
    stream_label = r.stream_label == "" ? null : r.stream_label
  } }) })
}
output "tables" {
  description = "Aggregate table identity, stream, tags and replica metadata keyed by logical identity."
  value = tomap({ for k, t in aws_dynamodb_table.this : k => {
    name         = t.name
    id           = t.id
    arn          = t.arn
    stream_arn   = t.stream_enabled ? t.stream_arn : null
    stream_label = t.stream_enabled ? t.stream_label : null
    tags_all     = t.tags_all
    replicas = tomap({ for r in t.replica : r.region_name => {
      arn          = r.arn
      stream_arn   = r.stream_arn == "" ? null : r.stream_arn
      stream_label = r.stream_label == "" ? null : r.stream_label
    } })
  } })
}
