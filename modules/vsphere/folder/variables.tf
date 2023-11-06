variable "custom_attributes" {
  description = "A list of custom attributes to apply to the folder. Unsupported on ESXi hosts, requires vCenter."
  type        = map(string)
  default     = {}
}

variable "datacenter_id" {
  description = "The ID of the datacenter where the folder should be created. Forces a new resource if changed."
}

variable "path" {
  description = "The path of the folder. Must be unique within the datacenter. This is relative to the root of the folder for the resource type being created."
}

variable "tags" {
  description = "A map of tags to assign to the folder."
  type        = map(string)
  default = {
    "terraform" = "true"
  }
}

variable "type" {
  description = "The type of the folder. Allowed options are: datacenter, host, vm, datastore, and network. If unset, the default is host."
  type        = string
  default     = "host"
}
