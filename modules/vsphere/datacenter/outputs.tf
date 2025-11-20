output "id" {
  description = "The ID of the datacenter."
  value       = vsphere_datacenter.this.id
}

output "moid" {
  description = "The Managed Object ID of the datacenter."
  value       = vsphere_datacenter.this.moid
}
