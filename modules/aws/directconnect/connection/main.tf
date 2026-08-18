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
  name            = var.name
  bandwidth       = var.bandwidth
  location        = var.location
  encryption_mode = var.encryption_mode
  provider_name   = var.provider_name
  region          = var.region
  request_macsec  = var.request_macsec
  tags            = merge(tomap({ Name = var.name }), var.tags)

  lifecycle {
    # Dedicated DX connections require physical provisioning and cannot be recreated, so this
    # module unconditionally guards against accidental destruction. There is intentionally no
    # variable to toggle this off: prevent_destroy must be a literal value, not one derived from
    # a variable. To decommission a circuit, cancel it with AWS/your carrier out-of-band, then
    # run `terraform state rm` on this resource before removing the module block. See the
    # README's "Notes / design decisions" section for the full rationale.
    prevent_destroy = true
  }
}
