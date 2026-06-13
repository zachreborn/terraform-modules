###########################
# General Variables
###########################

variable "name" {
  description = "(Required) Name for the IPAM. Used as the tag `Name` value and as a prefix for pool, scope, and RAM share names."
  type        = string
}

variable "description" {
  description = "(Optional) A description for the IPAM."
  type        = string
  default     = null
}

variable "tags" {
  description = "(Optional) A map of tags to assign to the IPAM and its child resources. A `Name` tag is merged in automatically."
  type        = map(string)
  default = {
    terraform   = "true"
    created_by  = "terraform"
    environment = "prod"
  }
}

###########################
# IPAM Instance Variables
###########################

variable "operating_regions" {
  description = "(Required) Determines which regions the IPAM is enabled to operate in. The region in which the IPAM is created must be included. Each entry is an AWS region name (e.g. us-east-1)."
  type        = list(string)

  validation {
    condition     = length(var.operating_regions) > 0
    error_message = "operating_regions must contain at least one region, including the region in which the IPAM is created."
  }
}

variable "tier" {
  description = "(Optional) IPAM tier. Valid values are `free` and `advanced`. The `advanced` tier is required for cross-region and AWS Organizations features."
  type        = string
  default     = "advanced"

  validation {
    condition     = contains(["free", "advanced"], var.tier)
    error_message = "tier must be either 'free' or 'advanced'."
  }
}

variable "enable_private_gua" {
  description = "(Optional) Enable this option to use your own GUA ranges as private IPv6 addresses. Defaults to the provider default when null."
  type        = bool
  default     = null
}

variable "metered_account" {
  description = "(Optional) The AWS account that is charged for active IP addresses managed in the IPAM. Valid values are `ipam-owner` and `resource-owner`. Defaults to the provider default when null."
  type        = string
  default     = null
}

variable "cascade" {
  description = "(Optional) Enables you to quickly delete an IPAM, its scopes, pools, and any allocations in the pools. Defaults to false to protect against accidental deletion."
  type        = bool
  default     = false
}

###########################
# Scope Variables
###########################

variable "enable_private_default_scope" {
  description = "(Optional) Whether the default private scope is available for pools to reference via `scope_key = \"private\"`. The default private scope always exists on the IPAM; this gate only controls module-side resolution."
  type        = bool
  default     = true
}

variable "enable_public_default_scope" {
  description = "(Optional) Whether the default public scope is available for pools to reference via `scope_key = \"public\"`. The default public scope always exists on the IPAM; this gate only controls module-side resolution."
  type        = bool
  default     = true
}

variable "additional_private_scopes" {
  description = "(Optional) Additional private scopes to create, keyed by logical name. Reference a scope from a pool via its key in `scope_key`."
  type = map(object({
    description = optional(string)
  }))
  default = {}
}

###########################
# Pool Variables
###########################

variable "pools" {
  description = <<-EOT
    (Optional) Map of IPAM pools keyed by logical name. Pools may be nested up to three levels deep
    (a pool, its parent, and its grandparent) by setting `parent_pool_key` to another pool's key.
    Fields:
      - address_family:                    "ipv4" or "ipv6".
      - scope_key:                         Scope to create the pool in: "private", "public", or an additional scope key. Defaults to "private".
      - parent_pool_key:                   Logical key of the parent pool for hierarchical pools.
      - locale:                            The region the pool is scoped to. Required for pools that allocate CIDRs to VPCs.
      - description:                       Description of the pool.
      - provisioned_cidrs:                 CIDRs to provision into the pool.
      - allocation_default_netmask_length: Default netmask length for allocations from this pool.
      - allocation_min_netmask_length:     Minimum netmask length for allocations from this pool.
      - allocation_max_netmask_length:     Maximum netmask length for allocations from this pool.
      - auto_import:                       Whether to auto-import discovered resources into the pool.
      - publicly_advertisable:             For public-scope IPv6 pools only.
      - aws_service:                       Limits the pool to a specific AWS service (e.g. "ec2") for public IPv6 pools.
      - public_ip_source:                  For public IPv4 pools: "amazon" or "byoip".
      - cascade:                           Enables deletion of the pool and its allocations.
      - allocation_resource_tags:          Tags required on resources to allocate from this pool.
      - tags:                              Additional tags for the pool.
  EOT
  type = map(object({
    address_family                    = string
    scope_key                         = optional(string)
    parent_pool_key                   = optional(string)
    locale                            = optional(string)
    description                       = optional(string)
    provisioned_cidrs                 = optional(list(string), [])
    allocation_default_netmask_length = optional(number)
    allocation_min_netmask_length     = optional(number)
    allocation_max_netmask_length     = optional(number)
    auto_import                       = optional(bool, false)
    publicly_advertisable             = optional(bool)
    aws_service                       = optional(string)
    public_ip_source                  = optional(string)
    cascade                           = optional(bool, false)
    allocation_resource_tags          = optional(map(string), {})
    tags                              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.pools : contains(["ipv4", "ipv6"], v.address_family)
    ])
    error_message = "Each pool address_family must be either 'ipv4' or 'ipv6'."
  }

  validation {
    condition = alltrue([
      for k, v in var.pools : v.parent_pool_key == null ? true : contains(keys(var.pools), v.parent_pool_key)
    ])
    error_message = "Each pool parent_pool_key must reference an existing key in var.pools."
  }

  validation {
    condition = alltrue([
      for k, v in var.pools : try(
        v.parent_pool_key == null ? true :
        var.pools[v.parent_pool_key].parent_pool_key == null ? true :
        var.pools[var.pools[v.parent_pool_key].parent_pool_key].parent_pool_key == null ? true :
        false,
        true
      )
    ])
    error_message = "Pool nesting cannot exceed three levels (a pool, its parent, and its grandparent)."
  }
}

###########################
# Allocation Variables
###########################

variable "allocations" {
  description = <<-EOT
    (Optional) Reserved/static CIDR allocations from a pool, keyed by logical name. Fields:
      - pool_key:         Logical key of the pool to allocate from (required).
      - cidr:             A specific CIDR to allocate. Conflicts with netmask_length.
      - netmask_length:   Netmask length to allocate from the pool. Conflicts with cidr.
      - description:      Description of the allocation.
      - disallowed_cidrs: CIDRs that should not be allocated from when using netmask_length.
      - tags:             Tags for the allocation.
  EOT
  type = map(object({
    pool_key         = string
    cidr             = optional(string)
    netmask_length   = optional(number)
    description      = optional(string)
    disallowed_cidrs = optional(list(string))
    tags             = optional(map(string), {})
  }))
  default = {}
}

###########################
# Organization & Sharing Variables
###########################

variable "delegated_admin_account_id" {
  description = "(Optional) When set, registers the given account ID as the IPAM delegated administrator for the AWS Organization. Must be applied from the Organization management account."
  type        = string
  default     = null
}

variable "share_with_organization" {
  description = "(Optional) When true, pools listed in `ram_share_pool_keys` are RAM-shared with the entire AWS Organization. When false, sharing targets the principals in `ram_principals`."
  type        = bool
  default     = false
}

variable "ram_principals" {
  description = "(Optional) Specific principals (account IDs or Organization/OU ARNs) to RAM-share pools with when `share_with_organization` is false."
  type        = list(string)
  default     = []
}

variable "ram_share_pool_keys" {
  description = "(Optional) Logical keys of the pools to share via RAM. Sharing is performed by composing the `modules/aws/ram` module; no RAM resources are declared inline."
  type        = list(string)
  default     = []
}
