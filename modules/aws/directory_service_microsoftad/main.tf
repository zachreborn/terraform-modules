terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_directory_service_directory" "microsoftad" {
  alias       = var.alias
  description = var.description
  edition     = var.edition
  enable_sso  = var.enable_sso
  name        = var.name
  password    = var.password
  short_name  = var.short_name
  size        = var.size
  tags        = var.tags
  type        = var.type

  vpc_settings {
    subnet_ids = var.subnet_ids
    vpc_id     = var.vpc_id
  }

  lifecycle {
    # AWS exposes no API for updating a directory's password: the entire
    # Directory Service API surface has no UpdateDirectory / UpdateCredentials
    # operation, and there is no `aws ds` CLI equivalent. Because there is no
    # update path, the provider marks password as Required + ForceNew
    # (internal/service/ds/directory.go), so any change to the value in config
    # REPLACES the directory -- destroying a managed domain along with every
    # resource joined to it. See hashicorp/terraform-provider-aws#16745, open
    # since 2020.
    #
    # Ignoring the diff costs no capability, since Terraform could never
    # legitimately apply a password change in the first place. Reset the Admin
    # password out of band instead (ResetUserPassword / console), and leave the
    # Terraform input alone. Callers who genuinely want a new directory must
    # replace it deliberately.
    ignore_changes = [password]
  }
}
