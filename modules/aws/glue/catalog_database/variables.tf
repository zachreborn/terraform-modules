###########################
# Database Variables
###########################

variable "name" {
  type        = string
  description = "(Required) Name of the Glue catalog database. Must contain only lowercase letters, numbers, and underscores."
  validation {
    condition     = can(regex("^[a-z0-9_]{1,255}$", var.name))
    error_message = "The database name must be 1-255 characters and contain only lowercase letters, numbers, and underscores."
  }
}

variable "catalog_id" {
  type        = string
  description = "(Optional) ID of the Glue Catalog to create the database in. If omitted, this defaults to the AWS Account ID."
  default     = null
}

variable "description" {
  type        = string
  description = "(Optional) Description of the database."
  default     = null
}

variable "location_uri" {
  type        = string
  description = "(Optional) Location of the database (for example, an HDFS or S3 path)."
  default     = null
}

variable "parameters" {
  type        = map(string)
  description = "(Optional) Map of key-value pairs that define parameters and properties of the database."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Map of tags to assign to the resource."
  default     = {}
}

###########################
# Nested Block Variables
###########################

variable "create_table_default_permission" {
  type = object({
    permissions = optional(list(string))
    principal = optional(object({
      data_lake_principal_identifier = optional(string)
    }))
  })
  description = "(Optional) Creates a set of default permissions on the table for principals. Provide the permissions list (for example, [\"ALL\"]) and the Lake Formation principal identifier."
  default     = null
}

variable "federated_database" {
  type = object({
    connection_name = optional(string)
    identifier      = optional(string)
  })
  description = "(Optional) Configuration block that references an entity outside the AWS Glue Data Catalog. Provide the connection_name of the Glue connection and the identifier of the federated database."
  default     = null
}

variable "target_database" {
  type = object({
    catalog_id    = string
    database_name = string
    region        = optional(string)
  })
  description = "(Optional) Configuration block for a target database for resource linking. Provide the catalog_id and database_name of the target, and optionally the region of the target database."
  default     = null
}
