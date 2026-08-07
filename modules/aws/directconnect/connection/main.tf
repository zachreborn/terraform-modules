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
  name              = var.name
  bandwidth         = var.bandwidth
  location          = var.location
  encryption_mode   = var.encryption_mode
  provider_name     = var.provider_name
  request_macsec    = var.request_macsec
  skip_destroy      = var.skip_destroy
  tags              = merge(tomap({ Name = var.name }), var.tags)

  lifecycle {
    # Dedicated DX connections require physical provisioning and cannot be recreated.
    # Set prevent_destroy = false only if you are intentionally decommissioning the circuit.
    prevent_destroy = true
  }
}
