output "id" {
  description = "The ID of the load balancer"
  value       = aws_lb.this.id
}

output "arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb.this.arn_suffix
}

output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = aws_lb.this.zone_id
}

output "name" {
  description = "The name of the load balancer"
  value       = aws_lb.this.name
}

output "vpc_id" {
  description = "The VPC ID of the load balancer"
  value       = aws_lb.this.vpc_id
}

output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = aws_lb_target_group.this
}

output "listeners" {
  description = "Map of listeners created and their attributes"
  value       = aws_lb_listener.this
}

output "listener_rules" {
  description = "Map of listener rules created and their attributes"
  value       = aws_lb_listener_rule.this
}
