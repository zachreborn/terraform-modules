output "waf_acl_id" {
  description = "The ID of the WAF WebACL"
  value       = aws_wafv2_web_acl.this.id
}

output "waf_acl_arn" {
  description = "The ARN of the WAF WebACL"
  value       = aws_wafv2_web_acl.this.arn
}

output "waf_acl_name" {
  description = "The name of the WAF WebACL"
  value       = aws_wafv2_web_acl.this.name
}

output "ip_sets" {
  description = "Map of created IP sets"
  value = {
    for k, v in aws_wafv2_ip_set.this : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

output "association_id" {
  description = "The ID of the WAF association (if created)"
  value       = length(aws_wafv2_web_acl_association.association) > 0 ? aws_wafv2_web_acl_association.association[0].id : null
}

output "associated_resource_arn" {
  description = "The ARN of the associated resource (if any)"
  value       = var.associate_with_resource
}
