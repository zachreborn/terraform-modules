output "dhcp_options_id" {
  description = "The ID of the DHCP Options Set."
  value       = aws_vpc_dhcp_options.this.id
}
