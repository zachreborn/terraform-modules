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

# Zscaler Private Access Connector - RHEL 9 Marketplace AMI
data "aws_ami" "zpa_connector_el9" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["zpa-connector-el9*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

###########################
# Locals
###########################
locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.zpa_connector_el9.id

  user_data = base64encode(templatefile("${path.module}/user_data.tftpl", {
    provisioning_key      = var.provisioning_key
    enable_ssm_agent      = var.enable_ssm_agent
    enable_host_os_update = var.enable_host_os_update
    aws_region            = data.aws_region.current.region
  }))

  asg_name = var.name
}

###########################
# Security Group
###########################
resource "aws_security_group" "zpa" {
  name        = var.sg_name
  description = "Zscaler ZPA App Connector ASG security group - egress only. Connectors initiate all sessions outbound to Zscaler cloud."
  vpc_id      = var.vpc_id

  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "All outbound traffic to Zscaler cloud endpoints, yum, and AWS APIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = var.sg_name })
}

###########################
# Launch Template
###########################
resource "aws_launch_template" "zpa" {
  name_prefix            = "${var.name}-"
  image_id               = local.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  user_data              = local.user_data
  update_default_version = true

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  # Marketplace RHEL AMI is pre-encrypted by Zscaler; AWS rejects re-encryption
  block_device_mappings {
    device_name = var.root_device_name

    ebs {
      delete_on_termination = var.root_delete_on_termination
      #tfsec:ignore:aws-ec2-encrypted-volumes
      encrypted   = var.encrypted
      volume_size = var.root_volume_size
      volume_type = var.root_volume_type
    }
  }

  metadata_options {
    http_endpoint               = var.http_endpoint
    http_tokens                 = var.http_tokens
    http_put_response_hop_limit = var.http_put_response_hop_limit
    instance_metadata_tags      = var.instance_metadata_tags
  }

  monitoring {
    enabled = var.monitoring
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    delete_on_termination       = true
    device_index                = 0
    security_groups             = [aws_security_group.zpa.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = var.instance_name_prefix
      role = "zpa_connector"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = var.instance_name_prefix
      role = "zpa_connector"
    })
  }

  tags = merge(var.tags, { Name = "${var.name}-lt" })
}

###########################
# Auto Scaling Group
###########################
resource "aws_autoscaling_group" "zpa" {
  name                      = local.asg_name
  vpc_zone_identifier       = var.subnet_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = var.default_cooldown
  termination_policies      = var.termination_policies
  max_instance_lifetime     = var.max_instance_lifetime
  capacity_rebalance        = var.capacity_rebalance
  enabled_metrics           = var.enabled_metrics

  launch_template {
    id      = aws_launch_template.zpa.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name = var.instance_name_prefix
      role = "zpa_connector"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

###########################
# Optional CPU target tracking (off by default for fixed 1/AZ)
###########################
resource "aws_autoscaling_policy" "cpu_target" {
  count = var.enable_cpu_target_tracking ? 1 : 0

  name                   = "${var.name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.zpa.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}
