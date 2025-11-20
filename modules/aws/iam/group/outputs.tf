output "arn" {
  description = "A map of ARNs assigned by AWS for the IAM groups."
  value = {
    for group in aws_iam_group.this : group.name => group.arn
  }
}

output "id" {
  description = "A map of IDs of the IAM groups."
  value = {
    for group in aws_iam_group.this : group.name => group.id
  }
}

output "path" {
  description = "A map of the paths for each IAM group."
  value = {
    for group in aws_iam_group.this : group.name => group.path
  }
}
