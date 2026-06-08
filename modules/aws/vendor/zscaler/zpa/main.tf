###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Data Sources
###########################
data "aws_region" "current" {}

# Zscaler publishes pre-built RHEL 9 App Connector AMIs via AWS Marketplace.
# The RHEL 9 license is included at no extra cost (covered by your Zscaler subscription).
# The connector software is pre-installed; user_data only injects the provisioning key.
# Marketplace subscription must be accepted before first apply:
#   https://aws.amazon.com/marketplace/pp/prodview-cvvqe5hxw2bku
data "aws_ami" "zpa_connector" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = ["by1wc5269g0048ix2nqvr0362"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

###########################
# Locals
###########################
locals {
  ami_id          = var.ami_id != null ? var.ami_id : data.aws_ami.zpa_connector.id
  connector_count = length(var.subnet_ids)
}

###########################
# Security Group
###########################

resource "aws_security_group" "zpa" {
  name        = var.sg_name
  description = "Zscaler ZPA App Connector security group - egress only. Connectors initiate all sessions outbound to Zscaler cloud."
  vpc_id      = var.vpc_id

  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "All outbound traffic to Zscaler cloud endpoints"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { "Name" = var.sg_name })
}

###########################
# EC2 Instances
###########################

resource "aws_instance" "zpa" {
  count                       = local.connector_count
  ami                         = local.ami_id
  iam_instance_profile        = var.iam_instance_profile
  instance_type               = var.instance_type
  key_name                    = var.key_name
  monitoring                  = var.monitoring
  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ips != null ? element(var.private_ips, count.index) : null
  subnet_id                   = element(var.subnet_ids, count.index)
  user_data_base64 = base64encode(templatefile("${path.module}/user_data.tftpl", {
    provisioning_key = var.provisioning_key
  }))
  vpc_security_group_ids = [aws_security_group.zpa.id]

  metadata_options {
    http_endpoint = var.http_endpoint
    http_tokens   = var.http_tokens
  }

  root_block_device {
    delete_on_termination = var.root_delete_on_termination
    # encrypted is intentionally omitted: the Marketplace AMI snapshot is already
    # encrypted by Zscaler. Setting encrypted=true triggers a re-encryption attempt
    # that AWS rejects for Marketplace snapshots. The volume remains encrypted at rest.
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    tags        = merge(var.tags, { "Name" = format("%s%02d", var.instance_name_prefix, count.index + 1) })
  }

  tags = merge(var.tags, { "Name" = format("%s%02d", var.instance_name_prefix, count.index + 1) })

  lifecycle {
    ignore_changes = [ami, user_data, user_data_base64]
  }
}

###########################
# CloudWatch Alarms
###########################

resource "aws_cloudwatch_metric_alarm" "instance" {
  actions_enabled     = true
  alarm_actions       = []
  alarm_description   = "ZPA App Connector EC2 StatusCheckFailed_Instance alarm"
  alarm_name          = format("%s-instance-alarm", aws_instance.zpa[count.index].id)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  count               = local.connector_count
  datapoints_to_alarm = 2
  dimensions = {
    InstanceId = aws_instance.zpa[count.index].id
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

resource "aws_cloudwatch_metric_alarm" "system" {
  actions_enabled     = true
  alarm_actions       = ["arn:aws:automate:${data.aws_region.current.region}:ec2:recover"]
  alarm_description   = "ZPA App Connector EC2 StatusCheckFailed_System alarm"
  alarm_name          = format("%s-system-alarm", aws_instance.zpa[count.index].id)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  count               = local.connector_count
  datapoints_to_alarm = 2
  dimensions = {
    InstanceId = aws_instance.zpa[count.index].id
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
