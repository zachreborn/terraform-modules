terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Data Sources
###########################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#############################
# API Gateway
#############################
resource "aws_apigatewayv2_api" "example" {
  name                       = var.name 
  protocol_type              = var.protocol_type
  route_selection_expression = "$request.body.action"
}

###################################################
CloudWatch Alarms
###################################################

#####################
# Status Check Failed Instance Metric
#####################

resource "aws_cloudwatch_metric_alarm" "instance" {
  actions_enabled     = true
  alarm_actions       = []
  alarm_description   = "EC2 instance StatusCheckFailed_Instance alarm"
  alarm_name          = format("%s-instance-alarm", aws_instance.ec2[count.index].id)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  count               = var.number
  datapoints_to_alarm = 2
  dimensions = {
    InstanceId = aws_instance.ec2[count.index].id
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
  #unit                      = var.unit
}

#####################
# Status Check Failed System Metric
#####################

resource "aws_cloudwatch_metric_alarm" "system" {
  actions_enabled     = true
  alarm_actions       = ["arn:aws:automate:${data.aws_region.current.name}:ec2:recover"]
  alarm_description   = "EC2 instance StatusCheckFailed_System alarm"
  alarm_name          = format("%s-system-alarm", aws_instance.ec2[count.index].id)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  count               = var.number
  datapoints_to_alarm = 2
  dimensions = {
    InstanceId = aws_instance.ec2[count.index].id
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
  #unit                      = var.unit
}
