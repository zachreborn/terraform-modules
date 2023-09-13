resource "vsphere_datacenter" "this" {
  name   = var.name
  folder = var.folder
  tags   = var.tags
}
