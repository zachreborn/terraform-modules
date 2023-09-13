variable "folder" {
  type        = string
  description = "The folder where the datacenter will be created. Forces a new resource if this is changed."
}

variable "name" {
  type        = string
  description = "The name of the datacenter. The name needs to be unique within the folder. Forces a new resource if this is changed."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the datacenter."
  default = {
    terraform = "true"
  }
}
