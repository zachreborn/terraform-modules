###########################
# VPC DHCP Options
###########################

resource "aws_vpc_dhcp_options" "dc_dns" {
  count               = var.enable_dhcp_options ? 1 : 0
  domain_name         = var.domain_name
  domain_name_servers = var.domain_name_servers
  ntp_servers         = var.ntp_servers
  tags                = var.tags
}

resource "aws_vpc_dhcp_options_association" "dc_dns" {
  count           = var.enable_dhcp_options ? 1 : 0
  dhcp_options_id = aws_vpc_dhcp_options.dc_dns[0].id
  vpc_id          = var.vpc_id
}
