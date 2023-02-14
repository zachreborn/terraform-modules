variable "zone_id" {
    type        = string
    description =  "(Required) The ID of the hosted zone to contain this record."
}

variable "name" {
    type        = string
    description =  "(Required) The name of the record."
}

variable "type" {
    type        = string
    description =  "(Required) The record type. Valid values are A, AAAA, CAA, CNAME, DS, MX, NAPTR, NS, PTR, SOA, SPF, SRV and TXT."
}

variable "ttl" {
    type        = number
    description = "(Optional, Required for non-alias records) The TTL of the record in seconds."
    default     = 300
}

variable "records" {
    type        = list(string)
    description = "(Required for non-alias records) A string list of records. To specify a single record value longer than 255 characters such as a TXT record for DKIM, add \"\" inside the Terraform configuration string."
}

variable "health_check_id" {
    type        = string
    description = "(Optional) The health check the record should be associated with."
    default     = null
}

variable "multivalue_answer_routing_policy_enabled" {
    type        = bool
    description = "(Optional) Set to true to indicate a multivalue answer routing policy. Conflicts with any other routing policy."
    default     = false
}
