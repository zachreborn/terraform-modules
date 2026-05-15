output "id" {
  value = aws_security_group.sg.id
}

output "name" {
  value = aws_security_group.sg.name
}

output "tags_all" {
  description = "A map of tags assigned to the security group, including provider default tags"
  value       = aws_security_group.sg.tags_all
}
