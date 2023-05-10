output "arn" {
  value = aws_key_pair.deployer_key.arn
}

output "key_name" {
  value = aws_key_pair.deployer_key.key_name
}
