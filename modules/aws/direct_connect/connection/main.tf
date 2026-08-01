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
# Direct Connect Connection
###########################

resource "aws_dx_connection" "this" {
  location        = var.location
  bandwidth       = var.bandwidth
  name            = var.connection_name
  provider_name   = var.provider_name
  request_macsec  = var.request_macsec
  encryption_mode = var.encryption_mode
  skip_destroy    = var.skip_destroy
  tags            = merge(tomap({ Name = var.connection_name }), var.tags)
}
