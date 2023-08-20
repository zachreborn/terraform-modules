########################################
# Route 53 Registered Domains
########################################
output "creation_dates" {
  description = "The creation date of the domain."
  value = {
    for domain in aws_route53domains_registered_domain.this :
    domain.domain_name => domain.creation_date
  }
}

output "expiration_dates" {
  description = "The expiration date of the domain."
  value = {
    for domain in aws_route53domains_registered_domain.this :
    domain.domain_name => domain.expiration_date
  }
}

output "updated_dates" {
  description = "The last updated date of the domain."
  value = {
    for domain in aws_route53domains_registered_domain.this :
    domain.domain_name => domain.updated_date
  }
}

output "whois_servers" {
  description = "The whois server of the domain."
  value = {
    for domain in aws_route53domains_registered_domain.this :
    domain.domain_name => domain.whois_server
  }
}
