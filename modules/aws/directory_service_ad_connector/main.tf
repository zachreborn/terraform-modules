terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_directory_service_directory" "connector" {
  alias       = var.alias
  description = var.description
  name        = var.name
  password    = var.password
  size        = var.size
  tags        = var.tags
  type        = var.type

  connect_settings {
    customer_dns_ips  = var.customer_dns_ips
    customer_username = var.customer_username
    subnet_ids        = var.subnet_ids
    vpc_id            = var.vpc_id
  }

  lifecycle {
    # AWS exposes no API for updating a directory's password: the entire
    # Directory Service API surface has no UpdateDirectory / UpdateCredentials
    # operation, and there is no `aws ds` CLI equivalent. Rotating an AD
    # Connector service account password is supported and recommended by AWS,
    # but the documented procedure is console-only:
    # https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ad_connector_update_creds.html
    #
    # Because there is no update path, the provider marks password as
    # Required + ForceNew (internal/service/ds/directory.go). Any change to the
    # value in config therefore REPLACES the directory, which silently destroys
    # everything registered against it -- for WorkSpaces that means a new
    # registration code and the loss of every desktop and user volume.
    # See hashicorp/terraform-provider-aws#16745, open since 2020.
    #
    # Ignoring the diff costs no capability, since Terraform could never
    # legitimately apply a password change in the first place. It converts a
    # destructive footgun into a no-op: rotate in AD, update via the console,
    # and leave the Terraform input alone. Callers who genuinely want to move to
    # a different service account must taint/replace the directory deliberately.
    ignore_changes = [password]
  }
}
