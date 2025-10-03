output "id" {
  description = "The ID of the load balancer"
  value       = aws_lb.load_balancer.id
}

output "arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.load_balancer.arn
}

output "arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb.load_balancer.arn_suffix
}

output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.load_balancer.dns_name
}

output "zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = aws_lb.load_balancer.zone_id
}

output "name" {
  description = "The name of the load balancer"
  value       = aws_lb.load_balancer.name
}

output "vpc_id" {
  description = "The VPC ID of the load balancer"
  value       = aws_lb.load_balancer.vpc_id
}

output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = aws_lb_target_group.target_group
}

output "listeners" {
  description = "Map of listeners created and their attributes"
  value       = aws_lb_listener.listener
}

output "listener_rules" {
  description = "Map of listener rules created and their attributes"
  value       = aws_lb_listener_rule.listener_rule
}
