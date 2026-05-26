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
# EC2 Dedicated Host
###########################

resource "aws_ec2_host" "host" {
  instance_type     = var.instance_type
  availability_zone = var.availability_zone
  host_recovery     = var.host_recovery
  auto_placement    = var.auto_placement

  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}
