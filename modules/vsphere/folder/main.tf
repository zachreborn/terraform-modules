terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/vsphere"
      version = ">= 2.5.0"
    }
  }
}


resource "vsphere_folder" "this" {
  custom_attributes = var.custom_attributes
  datacenter_id     = var.datacenter_id
  path              = var.path
  tags              = var.tags
  type              = var.type
}
