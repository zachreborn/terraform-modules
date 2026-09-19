###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr IAM Team IDs, keyed by the same keys as var.teams."
  value       = { for k, v in scalr_iam_team.this : k => v.id }
}
