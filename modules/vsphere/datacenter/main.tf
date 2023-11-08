terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/vsphere"
      version = ">= 2.5.0"
    }
  }
}

resource "vsphere_datacenter" "this" {
  folder = var.folder
  name   = var.name
  tags   = var.tags
}
