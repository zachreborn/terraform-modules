resource "vsphere_datacenter" "this" {
  folder = var.folder
  name   = var.name
  tags   = var.tags
}
