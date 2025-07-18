terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

############################################
# Data Sources
############################################
# data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ami" "velocloud" {
  most_recent = true
  name_regex  = "VeloCloud VCE ${var.velocloud_version}*"
  owners      = ["679593333241"] # VMware

  filter {
    name   = "state"
    values = ["available"]
  }
}

############################################
# Security Groups
############################################

resource "aws_security_group" "velocloud_lan_sg" {
  name        = var.lan_sg_name
  description = "Security group applied to VeloCloud SDWAN instance LAN NICs for SDWAN communication"
  vpc_id      = var.vpc_id

  ingress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # VeloCloud requires this port to be open in order to pass traffic from sources to the SDWAN.
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = var.velocloud_lan_cidr_blocks
  }

  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # VeloCloud requires this port to be open in order to pass traffic to the SDWAN.
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, ({ "Name" = format("%s", var.lan_sg_name) }))
}

resource "aws_security_group" "sdwan_mgmt_sg" {
  name        = var.mgmt_sg_name
  description = "Security group applied to the VeloCloud SDWAN instance WAN and MGMT NICs for VeloCloud communication"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access for support"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = var.ssh_mgmt_access_cidr_blocks
  }

  ingress {
    description = "SNMP access for management"
    from_port   = 161
    to_port     = 161
    protocol    = "UDP"
    cidr_blocks = var.snmp_mgmt_access_cidr_blocks
  }

  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # VeloCloud SDWAN requires this port to be open to the internet
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, ({ "Name" = format("%s", var.mgmt_sg_name) }))
}

resource "aws_security_group" "sdwan_wan_sg" {
  name        = var.wan_sg_name
  description = "Security group applied to the VeloCloud SDWAN instance WAN NIC for VeloCloud communication"
  vpc_id      = var.vpc_id

  ingress {
    description = "VMware Multipath Protocol"
    from_port   = 2426
    to_port     = 2426
    protocol    = "UDP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # VeloCloud SDWAN requires this port to be open to the internet
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, ({ "Name" = format("%s", var.wan_sg_name) }))
}

############################################
# EIP
############################################

resource "aws_eip" "wan_external_ip" {
  count  = length(var.velocloud_activation_keys)
  domain = "vpc"
  tags   = merge(var.tags, ({ "Name" = format("%s%d_wan", var.instance_name_prefix, count.index + 1) }))
}

resource "aws_eip_association" "wan_external_ip" {
  count                = length(var.velocloud_activation_keys)
  allocation_id        = element(aws_eip.wan_external_ip[*].id, count.index)
  network_interface_id = element(aws_network_interface.public_nic[*].id, count.index)
}

############################################
# ENI
############################################

resource "aws_network_interface" "mgmt_nic" {
  # Ge1 is the management interface in VeloCloud and attached at eth0
  count             = length(var.velocloud_activation_keys)
  description       = var.mgmt_nic_description
  private_ips       = var.mgmt_ips == null ? null : [element(var.mgmt_ips, count.index)]
  security_groups   = [aws_security_group.sdwan_mgmt_sg.id]
  source_dest_check = var.source_dest_check
  subnet_id         = element(var.public_subnet_ids, count.index)
  tags              = merge(var.tags, ({ "Name" = format("%s%d_mgmt", var.instance_name_prefix, count.index + 1) }))
}

resource "aws_network_interface" "public_nic" {
  # Ge2 is the public interface in VeloCloud and attached at eth1
  count             = length(var.velocloud_activation_keys)
  description       = var.public_nic_description
  private_ips       = var.public_ips == null ? null : [element(var.public_ips, count.index)]
  security_groups   = [aws_security_group.sdwan_wan_sg.id]
  source_dest_check = var.source_dest_check
  subnet_id         = element(var.public_subnet_ids, count.index)
  tags              = merge(var.tags, ({ "Name" = format("%s%d_public", var.instance_name_prefix, count.index + 1) }))
}

resource "aws_network_interface" "private_nic" {
  # Ge3 is the private interface in VeloCloud and attached at eth2
  count             = length(var.velocloud_activation_keys)
  description       = var.private_nic_description
  private_ips       = var.private_ips == null ? null : [element(var.private_ips, count.index)]
  security_groups   = [aws_security_group.velocloud_lan_sg.id]
  source_dest_check = var.source_dest_check
  subnet_id         = element(var.private_subnet_ids, count.index)
  tags              = merge(var.tags, ({ "Name" = format("%s%d_private", var.instance_name_prefix, count.index + 1) }))
}

############################################
# EC2 Instance
############################################

resource "aws_instance" "ec2_instance" {
  ami                  = var.ami_id != null ? var.ami_id : data.aws_ami.velocloud.id
  count                = length(var.velocloud_activation_keys)
  ebs_optimized        = var.ebs_optimized
  hibernation          = var.hibernation
  iam_instance_profile = var.iam_instance_profile
  instance_type        = var.instance_type
  key_name             = var.key_name
  monitoring           = var.monitoring
  volume_tags          = merge(var.tags, ({ "Name" = format("%s%d", var.instance_name_prefix, count.index + 1) }))
  tags                 = merge(var.tags, ({ "Name" = format("%s%d", var.instance_name_prefix, count.index + 1) }))
  user_data = var.user_data != null ? var.user_data : base64encode(templatefile("${path.module}/user_data.tftpl", {
    velocloud_activation_key     = element(var.velocloud_activation_keys, count.index)
    velocloud_ignore_cert_errors = var.velocloud_ignore_cert_errors
    velocloud_orchestrator       = var.velocloud_orchestrator
  }))

  metadata_options {
    http_endpoint = var.http_endpoint
    http_tokens   = var.http_tokens
  }

  network_interface {
    network_interface_id = element(aws_network_interface.mgmt_nic[*].id, count.index)
    device_index         = 0
  }

  network_interface {
    network_interface_id = element(aws_network_interface.public_nic[*].id, count.index)
    device_index         = 1
  }

  network_interface {
    network_interface_id = element(aws_network_interface.private_nic[*].id, count.index)
    device_index         = 2
  }

  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    encrypted   = var.root_ebs_volume_encrypted
  }

  depends_on = [
    aws_eip.wan_external_ip,
    aws_network_interface.mgmt_nic,
    aws_network_interface.public_nic,
    aws_network_interface.private_nic
  ]
}

###################################################
# CloudWatch Alarms
###################################################

#####################
# Status Check Failed Instance Metric
#####################

resource "aws_cloudwatch_metric_alarm" "instance" {
  actions_enabled     = true
  alarm_actions       = []
  alarm_description   = "EC2 instance StatusCheckFailed_Instance alarm"
  alarm_name          = format("%s-instance-alarm", element(aws_instance.ec2_instance[*].id, count.index))
  comparison_operator = "GreaterThanOrEqualToThreshold"
  count               = length(var.velocloud_activation_keys)
  datapoints_to_alarm = 2
  dimensions = {
    InstanceId = element(aws_instance.ec2_instance[*].id, count.index)
  }
  evaluation_periods        = "2"
  insufficient_data_actions = []
  metric_name               = "StatusCheckFailed_Instance"
  namespace                 = "AWS/EC2"
  ok_actions                = []
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "1"
  treat_missing_data        = "missing"
}

#####################
# Status Check Failed System Metric
#####################

resource "aws_cloudwatch_metric_alarm" "system" {
  actions_enabled     = true
  alarm_actions       = ["arn:aws:automate:${data.aws_region.current.region}:ec2:recover"]
  alarm_description   = "EC2 instance StatusCheckFailed_System alarm"
  alarm_name          = format("%s-system-alarm", element(aws_instance.ec2_instance[*].id, count.index))
  comparison_operator = "GreaterThanOrEqualToThreshold"
  count               = length(var.velocloud_activation_keys)
  datapoints_to_alarm = 2
  dimensions = {
    InstanceId = element(aws_instance.ec2_instance[*].id, count.index)
  }
  evaluation_periods        = "2"
  insufficient_data_actions = []
  metric_name               = "StatusCheckFailed_System"
  namespace                 = "AWS/EC2"
  ok_actions                = []
  period                    = "60"
  statistic                 = "Maximum"
  threshold                 = "1"
  treat_missing_data        = "missing"
}
