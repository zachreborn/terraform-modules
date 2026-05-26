output "id" {
  description = "The ID of the Dedicated Host."
  value       = aws_ec2_host.host.id
}

output "arn" {
  description = "The ARN of the Dedicated Host."
  value       = aws_ec2_host.host.arn
}

output "availability_zone" {
  description = "The Availability Zone of the Dedicated Host."
  value       = aws_ec2_host.host.availability_zone
}

output "instance_type" {
  description = "The instance type supported by the Dedicated Host."
  value       = aws_ec2_host.host.instance_type
}
