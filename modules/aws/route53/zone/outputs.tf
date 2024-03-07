output "name_servers" {
  description = "A map of zones and their list of name servers."
  value = {
    for zone in aws_route53_zone.zone : zone.name => zone.name_servers
  }
}

output "zone_id" {
  description = "A map of zones and their zone IDs."
  value = {
    for zone in aws_route53_zone.zone : zone.name => zone.zone_id
  }
}
