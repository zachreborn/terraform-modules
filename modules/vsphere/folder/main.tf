resource "vsphere_folder" "this" {
  custom_attributes = var.custom_attributes
  datacenter_id     = var.datacenter_id
  path              = var.path
  tags              = var.tags
  type              = var.type
}