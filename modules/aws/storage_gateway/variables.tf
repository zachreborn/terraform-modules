###########################
# Storage Gateway
###########################

variable "activation_key" {
  type        = string
  description = "(Optional) Gateway activation key obtained after deploying and powering on the on-premises gateway VM. Mutually exclusive with gateway_ip_address; supply exactly one. Use this when you have already retrieved the activation key out of band. Marked sensitive: unlike the gateway's password arguments, the provider does not flag activation_key as sensitive, so without this it would render in plan output and CI logs. It is still persisted in Terraform state in plaintext - supply it from a secret store and protect state access accordingly."
  default     = null
  sensitive   = true
  validation {
    condition     = var.activation_key == null ? true : length(var.activation_key) >= 1 && length(var.activation_key) <= 50
    error_message = "The value of activation_key must be null or between 1 and 50 characters, per the ActivateGateway API."
  }
}

variable "cloudwatch_log_group_arn" {
  type        = string
  description = "(Optional) ARN of an existing CloudWatch log group to use for gateway health logs. When null and create_cloudwatch_log_group is true, this module creates one. Defaults to null."
  default     = null
  validation {
    condition     = var.cloudwatch_log_group_arn == null ? true : can(regex("^arn:[^:]+:logs:[^:]+:[0-9]{12}:log-group:.+$", var.cloudwatch_log_group_arn))
    error_message = "cloudwatch_log_group_arn must be null or a valid CloudWatch Logs log group ARN (arn:<partition>:logs:<region>:<account>:log-group:<name>)."
  }
}

variable "gateway_arn" {
  type        = string
  description = "(Optional) ARN of an existing, externally activated gateway for this module to manage cache disks and file shares on, instead of creating one. Use for on-premises appliances, which only honor an activation for a short window after the activation key is generated - too short for pipeline-driven applies - so they must be activated out of band. When set, the module creates no gateway and the gateway-level arguments (activation_key, gateway_ip_address, gateway_vpc_endpoint, gateway_timezone, smb_active_directory_settings, maintenance_start_time, SMB settings, cloudwatch_log_group_arn wiring) are not applied; configure those on the gateway out of band. The module also cannot see an adopted gateway's type, so the gateway_type checks on file shares and file system associations are skipped in this mode. Defaults to null."
  default     = null
  validation {
    condition     = var.gateway_arn == null ? true : can(regex("^arn:[^:]+:storagegateway:[^:]+:[0-9]{12}:gateway/sgw-[0-9A-Fa-f]+$", var.gateway_arn))
    error_message = "gateway_arn must be null or a valid Storage Gateway gateway ARN (arn:<partition>:storagegateway:<region>:<account>:gateway/sgw-XXXXXXXX)."
  }
}

variable "gateway_ip_address" {
  type        = string
  description = "(Optional) IP address of the gateway VM, used to fetch the activation key automatically during apply. Mutually exclusive with activation_key; supply exactly one. The VM must be reachable from where Terraform runs. Defaults to null."
  default     = null
  validation {
    condition     = var.gateway_ip_address == null ? true : can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$", var.gateway_ip_address))
    error_message = "gateway_ip_address must be null or a valid IPv4 address."
  }
}

variable "gateway_name" {
  type        = string
  description = "(Required) Name of the gateway. Also used as the Name tag. Between 2 and 255 characters."
  validation {
    condition     = length(var.gateway_name) >= 2 && length(var.gateway_name) <= 255
    error_message = "The value of gateway_name must be between 2 and 255 characters, per the ActivateGateway API."
  }
}

variable "gateway_timezone" {
  type        = string
  description = "(Optional) Time zone for the gateway, in the format GMT, GMT-hh:mm, or GMT+hh:mm (e.g. GMT-7:00). Offsets run from GMT-12:00 to GMT+14:00, matching the range of real-world time zones. Defaults to GMT."
  default     = "GMT"

  # Positive offsets reach +14:00 (Line Islands) and negative offsets stop at
  # -12:00. The API documents only the GMT[+-]hh:mm shape and a 10-character
  # length cap, so the real-world range is enforced here. The two endpoint hours
  # are special-cased to minute 00 so GMT+14:59 and GMT-12:59, which are past the
  # documented bounds, are not accepted.
  validation {
    condition     = can(regex("^GMT([+](0?[0-9]|1[0-3]):[0-5][0-9]|[+]14:00|[-](0?[0-9]|1[0-1]):[0-5][0-9]|[-]12:00)?$", var.gateway_timezone))
    error_message = "The value of gateway_timezone must be GMT, or GMT followed by an offset from GMT-12:00 to GMT+14:00 in the format GMT-hh:mm or GMT+hh:mm (for example GMT-7:00)."
  }
}

variable "gateway_type" {
  type        = string
  description = "(Optional) Type of the gateway. This module manages file gateways, so valid values are FILE_S3 and FILE_FSX_SMB. Defaults to FILE_S3. S3 SMB/NFS file shares require FILE_S3; FSx file system associations require FILE_FSX_SMB. Note that Amazon FSx File Gateway (FILE_FSX_SMB) is no longer available to new AWS customers - existing customers can continue to use it, which is why it remains a supported value but is not the default."
  default     = "FILE_S3"
  validation {
    condition     = contains(["FILE_FSX_SMB", "FILE_S3"], var.gateway_type)
    error_message = "The value of gateway_type must be one of FILE_FSX_SMB or FILE_S3."
  }
}

variable "gateway_vpc_endpoint" {
  type        = string
  description = "(Optional) VPC endpoint DNS name to use for the gateway's connection to the Storage Gateway service when using a private (VPC) endpoint. Defaults to null."
  default     = null
}

variable "maintenance_start_time" {
  type = object({
    hour_of_day    = number
    minute_of_hour = number
    day_of_week    = optional(number)
    day_of_month   = optional(number)
  })
  description = "(Optional) Weekly or monthly maintenance window. Supply hour_of_day (0-23) and minute_of_hour (0-59), plus exactly one of day_of_week (0-6, Sunday=0) for a weekly window or day_of_month (1-28) for a monthly window. UpdateMaintenanceStartTime rejects an incomplete schedule outright, so all four pieces are enforced here rather than at apply. Defaults to null, which lets the gateway pick its own window."
  default     = null

  # The provider does range-check day_of_week (0-6) and day_of_month (1-28) with its
  # nullable-int validators, but it reports failures against the nested resource block.
  # These validations fail against the module's own variable with a message naming the
  # module input, and additionally cover the weekly-xor-monthly rule below, which the
  # provider does not enforce at all.
  validation {
    condition     = var.maintenance_start_time == null ? true : var.maintenance_start_time.hour_of_day >= 0 && var.maintenance_start_time.hour_of_day <= 23
    error_message = "The value of maintenance_start_time.hour_of_day must be between 0 and 23."
  }

  validation {
    condition     = var.maintenance_start_time == null ? true : var.maintenance_start_time.minute_of_hour >= 0 && var.maintenance_start_time.minute_of_hour <= 59
    error_message = "The value of maintenance_start_time.minute_of_hour must be between 0 and 59."
  }

  validation {
    condition     = try(var.maintenance_start_time.day_of_week, null) == null ? true : var.maintenance_start_time.day_of_week >= 0 && var.maintenance_start_time.day_of_week <= 6
    error_message = "The value of maintenance_start_time.day_of_week must be between 0 (Sunday) and 6 (Saturday)."
  }

  # AWS cannot schedule maintenance on days 29-31, so the monthly window stops at 28.
  validation {
    condition     = try(var.maintenance_start_time.day_of_month, null) == null ? true : var.maintenance_start_time.day_of_month >= 1 && var.maintenance_start_time.day_of_month <= 28
    error_message = "The value of maintenance_start_time.day_of_month must be between 1 and 28; AWS cannot start maintenance on days 29 through 31."
  }

  # A window is weekly or monthly - exactly one, never both and never neither. AWS
  # documents that a complete schedule requires MinuteOfHour, HourOfDay, and either
  # DayOfMonth or DayOfWeek, and rejects the whole request if the schedule is
  # incomplete. The provider forwards whatever it is given, so enforce the XOR here.
  validation {
    condition     = var.maintenance_start_time == null ? true : (try(var.maintenance_start_time.day_of_week, null) != null) != (try(var.maintenance_start_time.day_of_month, null) != null)
    error_message = "Set exactly one of maintenance_start_time.day_of_week (weekly window) or maintenance_start_time.day_of_month (monthly window); AWS rejects a maintenance schedule that specifies both or neither."
  }
}

variable "smb_active_directory_settings" {
  type = object({
    domain_name         = string
    password            = string
    username            = string
    domain_controllers  = optional(list(string))
    organizational_unit = optional(string)
    timeout_in_seconds  = optional(number)
  })
  description = "(Optional) Microsoft Active Directory join settings for SMB access. Required to associate an FSx for Windows file system on a FILE_FSX_SMB gateway. domain_name, username, and password are the join credentials; domain_controllers, organizational_unit, and timeout_in_seconds are optional. This entire object is marked sensitive because it carries the join password, so its values are redacted from plan/apply output. The password is still stored in Terraform state in plaintext - the provider offers no write-only alternative for this argument - so supply it from a secret store and protect state access accordingly. Defaults to null."
  default     = null
  sensitive   = true
}

variable "smb_file_share_visibility" {
  type        = bool
  description = "(Optional) Whether file shares on this gateway are visible when listing shares for the gateway's domain. Defaults to null, which uses the service default."
  default     = null
}

variable "smb_guest_password" {
  type        = string
  description = "(Optional) Guest password for guest access to SMB file shares. Marked sensitive so it is redacted from plan/apply output. Still stored in Terraform state in plaintext - supply it from a secret store and protect state access accordingly. Defaults to null."
  default     = null
  sensitive   = true
}

variable "smb_security_strategy" {
  type        = string
  description = "(Optional) Specifies the type of security strategy for the gateway. Defaults to MandatorySigning, which requires SMB signing on every connection and protects against tampering and relay attacks. AWS's own default is ClientSpecified, which enforces nothing and leaves signing to client negotiation - set it explicitly if you must support legacy clients that cannot sign. MandatoryEncryption is stricter still (it requires SMB3 encryption) but rejects clients that cannot negotiate SMB3. Set to null to defer entirely to the service default."
  default     = "MandatorySigning"
  validation {
    condition     = var.smb_security_strategy == null ? true : contains(["ClientSpecified", "MandatorySigning", "MandatoryEncryption"], var.smb_security_strategy)
    error_message = "The value of smb_security_strategy must be null, ClientSpecified, MandatorySigning, or MandatoryEncryption."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resources created by this module."
  default     = {}
}

###########################
# Cache Disks
###########################

variable "cache_disk_ids" {
  type        = set(string)
  description = "(Optional) Set of local disk IDs (as reported by the gateway, e.g. via the aws_storagegateway_local_disk data source) to allocate as cache storage. Defaults to an empty set. Note: cache allocation is write-once (the API cannot remove or resize cache), and some hypervisors re-identify allocated disks by UUID, causing permanent replacement diffs - for externally activated gateways (gateway_arn), prefer allocating cache out of band with add-cache and leaving this empty."
  default     = []
}

###########################
# File System Associations
###########################

variable "file_system_associations" {
  type = map(object({
    location_arn          = string
    password              = string
    username              = string
    audit_destination_arn = optional(string)
    cache_attributes = optional(object({
      cache_stale_timeout_in_seconds = optional(number)
    }))
  }))
  description = "(Optional) Map of FSx for Windows File Server associations keyed by a logical name. Per association: location_arn (the FSx for Windows file system ARN — e.g. the arn output of the fsx module), username/password (a domain user with access to the file system), optional audit_destination_arn (CloudWatch log group ARN for SMB audit logs), and an optional cache_attributes block with cache_stale_timeout_in_seconds. Requires gateway_type FILE_FSX_SMB. Defaults to {}. This variable is deliberately NOT marked sensitive: it drives a resource for_each, and Terraform forbids sensitive values there because the map keys become resource instance addresses. Each password is still redacted in plan output because the provider marks the underlying password argument sensitive, but it is stored in Terraform state in plaintext - supply it from a secret store and protect state access accordingly."
  default     = {}

  # Unlike a file share's location_arn (which may also be an access point ARN or an access
  # point alias), an association's location_arn is always an FSx file system ARN.
  validation {
    condition = alltrue([
      for association in var.file_system_associations : can(regex("^arn:[^:]+:fsx:[^:]+:[0-9]{12}:file-system/fs-[0-9a-f]+$", association.location_arn))
    ])
    error_message = "Each file_system_associations location_arn must be an FSx file system ARN (arn:<partition>:fsx:<region>:<account>:file-system/fs-XXXXXXXX)."
  }

  validation {
    condition = alltrue([
      for association in var.file_system_associations : association.audit_destination_arn == null ? true : can(regex("^arn:[^:]+:logs:[^:]+:[0-9]{12}:log-group:.+$", association.audit_destination_arn))
    ])
    error_message = "Each file_system_associations audit_destination_arn must be null or a CloudWatch Logs log group ARN."
  }
}

###########################
# S3 File Shares
###########################

variable "s3_smb_file_shares" {
  type = map(object({
    location_arn             = string
    role_arn                 = optional(string)
    authentication           = optional(string)
    access_based_enumeration = optional(bool)
    admin_user_list          = optional(set(string))
    audit_destination_arn    = optional(string)
    bucket_region            = optional(string)
    case_sensitivity         = optional(string)
    default_storage_class    = optional(string)
    file_share_name          = optional(string)
    guess_mime_type_enabled  = optional(bool)
    invalid_user_list        = optional(set(string))
    kms_encrypted            = optional(bool)
    kms_key_arn              = optional(string)
    notification_policy      = optional(string)
    object_acl               = optional(string)
    oplocks_enabled          = optional(bool)
    read_only                = optional(bool)
    requester_pays           = optional(bool)
    smb_acl_enabled          = optional(bool)
    valid_user_list          = optional(set(string))
    vpc_endpoint_dns_name    = optional(string)
    cache_attributes = optional(object({
      cache_stale_timeout_in_seconds = optional(number)
    }))
  }))
  description = "(Optional) Map of S3 SMB file shares keyed by a logical name (used as the Name tag). Requires gateway_type FILE_S3. Per share: location_arn (the S3 bucket ARN, optionally with a /prefix, that this share exposes); role_arn (an IAM role the gateway assumes to access the bucket — defaults to the role this module creates when create_iam_role is true); authentication (ActiveDirectory or GuestAccess — ActiveDirectory requires the gateway be domain joined via smb_active_directory_settings); admin_user_list/valid_user_list/invalid_user_list (AD users or groups); notification_policy (JSON notification policy); and the usual share tunables (read_only, object_acl, default_storage_class, cache_attributes, etc.). Defaults to {}."
  default     = {}
  validation {
    condition = alltrue([
      for share in var.s3_smb_file_shares : share.authentication == null ? true : contains(["ActiveDirectory", "GuestAccess"], share.authentication)
    ])
    error_message = "Each s3_smb_file_shares authentication must be null, ActiveDirectory, or GuestAccess."
  }

  # A bucket ARN (optionally with a /prefix) or an S3 access point ARN. The CreateSMBFileShare
  # API also accepts a bare access point alias, but the provider runs its own ARN check on this
  # argument and rejects any non-ARN value, so an alias cannot be used here.
  validation {
    condition = alltrue([
      for share in var.s3_smb_file_shares : can(regex("^arn:[^:]+:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9](/.*)?$", share.location_arn)) || can(regex("^arn:[^:]+:s3:[^:]+:[0-9]{12}:accesspoint/[^/]+(/.*)?$", share.location_arn))
    ])
    error_message = "Each s3_smb_file_shares location_arn must be an S3 bucket ARN (arn:aws:s3:::my-bucket, optionally with a /prefix) or an S3 access point ARN. The provider rejects bare access point aliases."
  }

  validation {
    condition = alltrue([
      for share in var.s3_smb_file_shares : share.case_sensitivity == null ? true : contains(["ClientSpecified", "CaseSensitive"], share.case_sensitivity)
    ])
    error_message = "Each s3_smb_file_shares case_sensitivity must be null, ClientSpecified, or CaseSensitive."
  }

  validation {
    condition = alltrue([
      for share in var.s3_smb_file_shares : share.default_storage_class == null ? true : contains(["S3_STANDARD", "S3_INTELLIGENT_TIERING", "S3_STANDARD_IA", "S3_ONEZONE_IA"], share.default_storage_class)
    ])
    error_message = "Each s3_smb_file_shares default_storage_class must be null, S3_STANDARD, S3_INTELLIGENT_TIERING, S3_STANDARD_IA, or S3_ONEZONE_IA."
  }

  validation {
    condition = alltrue([
      for share in var.s3_smb_file_shares : share.object_acl == null ? true : contains(["private", "public-read", "public-read-write", "authenticated-read", "bucket-owner-read", "bucket-owner-full-control", "aws-exec-read"], share.object_acl)
    ])
    error_message = "Each s3_smb_file_shares object_acl must be null or one of the canned ACLs Storage Gateway accepts: private, public-read, public-read-write, authenticated-read, bucket-owner-read, bucket-owner-full-control, aws-exec-read."
  }

  validation {
    condition = alltrue([
      for share in var.s3_smb_file_shares : share.role_arn == null ? true : can(regex("^arn:[^:]+:iam::[0-9]{12}:role/.+$", share.role_arn))
    ])
    error_message = "Each s3_smb_file_shares role_arn must be null or a valid IAM role ARN (arn:<partition>:iam::<account>:role/<name>)."
  }

  # The CreateSMBFileShare API also accepts a bare alias/<name>, but the provider runs its own
  # ARN check on this argument and rejects anything that is not a full ARN, so an alias must be
  # given in ARN form.
  validation {
    condition = alltrue([
      for share in var.s3_smb_file_shares : share.kms_key_arn == null ? true : can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:(key|alias)/.+$", share.kms_key_arn))
    ])
    error_message = "Each s3_smb_file_shares kms_key_arn must be null or a KMS key or alias ARN. The provider rejects a bare alias/<name>, so give an alias as arn:<partition>:kms:<region>:<account>:alias/<name>."
  }

  # AWS ignores KMSKey unless KMSEncrypted is true and silently falls back to SSE-S3,
  # so a share configured with a key but without kms_encrypted would look encrypted
  # with a customer key while it is not.
  validation {
    condition = alltrue([
      for share in var.s3_smb_file_shares : share.kms_key_arn == null ? true : share.kms_encrypted == true
    ])
    error_message = "Each s3_smb_file_shares share that sets kms_key_arn must also set kms_encrypted = true; AWS ignores the key otherwise and encrypts with SSE-S3."
  }
}

variable "s3_nfs_file_shares" {
  type = map(object({
    location_arn            = string
    client_list             = set(string)
    role_arn                = optional(string)
    audit_destination_arn   = optional(string)
    bucket_region           = optional(string)
    default_storage_class   = optional(string)
    file_share_name         = optional(string)
    guess_mime_type_enabled = optional(bool)
    kms_encrypted           = optional(bool)
    kms_key_arn             = optional(string)
    notification_policy     = optional(string)
    object_acl              = optional(string)
    read_only               = optional(bool)
    requester_pays          = optional(bool)
    squash                  = optional(string)
    vpc_endpoint_dns_name   = optional(string)
    nfs_file_share_defaults = optional(object({
      directory_mode = optional(string)
      file_mode      = optional(string)
      group_id       = optional(number)
      owner_id       = optional(number)
    }))
    cache_attributes = optional(object({
      cache_stale_timeout_in_seconds = optional(number)
    }))
  }))
  description = "(Optional) Map of S3 NFS file shares keyed by a logical name (used as the Name tag). Requires gateway_type FILE_S3. Per share: location_arn (the S3 bucket ARN, optionally with a /prefix, that this share exposes); client_list (set of CIDRs/IPs allowed to mount the share); role_arn (an IAM role the gateway assumes to access the bucket — defaults to the role this module creates when create_iam_role is true); squash (RootSquash, NoSquash, or AllSquash); notification_policy (JSON notification policy); an optional nfs_file_share_defaults block (POSIX directory_mode/file_mode/group_id/owner_id for new objects); and the usual share tunables (read_only, object_acl, default_storage_class, cache_attributes, etc.). Defaults to {}."
  default     = {}
  validation {
    condition = alltrue([
      for share in var.s3_nfs_file_shares : share.squash == null ? true : contains(["RootSquash", "NoSquash", "AllSquash"], share.squash)
    ])
    error_message = "Each s3_nfs_file_shares squash must be null, RootSquash, NoSquash, or AllSquash."
  }

  # See the equivalent validation on s3_smb_file_shares for why aliases are not accepted.
  validation {
    condition = alltrue([
      for share in var.s3_nfs_file_shares : can(regex("^arn:[^:]+:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9](/.*)?$", share.location_arn)) || can(regex("^arn:[^:]+:s3:[^:]+:[0-9]{12}:accesspoint/[^/]+(/.*)?$", share.location_arn))
    ])
    error_message = "Each s3_nfs_file_shares location_arn must be an S3 bucket ARN (arn:aws:s3:::my-bucket, optionally with a /prefix) or an S3 access point ARN. The provider rejects bare access point aliases."
  }

  validation {
    condition = alltrue([
      for share in var.s3_nfs_file_shares : share.default_storage_class == null ? true : contains(["S3_STANDARD", "S3_INTELLIGENT_TIERING", "S3_STANDARD_IA", "S3_ONEZONE_IA"], share.default_storage_class)
    ])
    error_message = "Each s3_nfs_file_shares default_storage_class must be null, S3_STANDARD, S3_INTELLIGENT_TIERING, S3_STANDARD_IA, or S3_ONEZONE_IA."
  }

  validation {
    condition = alltrue([
      for share in var.s3_nfs_file_shares : share.object_acl == null ? true : contains(["private", "public-read", "public-read-write", "authenticated-read", "bucket-owner-read", "bucket-owner-full-control", "aws-exec-read"], share.object_acl)
    ])
    error_message = "Each s3_nfs_file_shares object_acl must be null or one of the canned ACLs Storage Gateway accepts: private, public-read, public-read-write, authenticated-read, bucket-owner-read, bucket-owner-full-control, aws-exec-read."
  }

  validation {
    condition = alltrue([
      for share in var.s3_nfs_file_shares : share.role_arn == null ? true : can(regex("^arn:[^:]+:iam::[0-9]{12}:role/.+$", share.role_arn))
    ])
    error_message = "Each s3_nfs_file_shares role_arn must be null or a valid IAM role ARN (arn:<partition>:iam::<account>:role/<name>)."
  }

  validation {
    condition = alltrue([
      for share in var.s3_nfs_file_shares : share.kms_key_arn == null ? true : can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:(key|alias)/.+$", share.kms_key_arn))
    ])
    error_message = "Each s3_nfs_file_shares kms_key_arn must be null or a KMS key or alias ARN. The provider rejects a bare alias/<name>, so give an alias as arn:<partition>:kms:<region>:<account>:alias/<name>."
  }

  # See the equivalent validation on s3_smb_file_shares: a key without kms_encrypted
  # is silently ignored by AWS in favour of SSE-S3.
  validation {
    condition = alltrue([
      for share in var.s3_nfs_file_shares : share.kms_key_arn == null ? true : share.kms_encrypted == true
    ])
    error_message = "Each s3_nfs_file_shares share that sets kms_key_arn must also set kms_encrypted = true; AWS ignores the key otherwise and encrypts with SSE-S3."
  }

  # client_list entries are CIDR blocks or bare IPv4 addresses that may mount the share.
  validation {
    condition = alltrue(flatten([
      for share in var.s3_nfs_file_shares : [
        for client in share.client_list : can(cidrnetmask(client)) || can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$", client))
      ]
    ]))
    error_message = "Each s3_nfs_file_shares client_list entry must be an IPv4 CIDR block (e.g. 10.0.0.0/16) or a single IPv4 address."
  }
}

###########################
# IAM Role for S3 Access
###########################

variable "create_iam_role" {
  type        = bool
  description = "(Optional) Determines whether this module creates the IAM role (and policy) that S3 file shares assume to read and write objects in their backing buckets. When true, s3_bucket_arns must list the buckets the role may access, and the generated policy additionally grants KMS permissions on any key referenced by a share's kms_key_arn. The generated policy is scoped to bucket ARNs only, so it cannot serve a share whose location_arn is an S3 access point - supply role_arn for those. Ignored when role_arn is supplied. Defaults to false."
  default     = false
}

variable "role_arn" {
  type        = string
  description = "(Optional) ARN of an existing IAM role for S3 file shares to assume when accessing their backing buckets. Takes precedence over create_iam_role. Used as the default role_arn for any share that does not set its own. Defaults to null."
  default     = null
  validation {
    condition     = var.role_arn == null ? true : can(regex("^arn:[^:]+:iam::[0-9]{12}:role/.+$", var.role_arn))
    error_message = "role_arn must be null or a valid IAM role ARN (arn:<partition>:iam::<account>:role/<name>). Note IAM ARNs carry no region."
  }
}

variable "s3_bucket_arns" {
  type        = list(string)
  description = "(Optional) Bucket ARNs the module-created IAM role is granted read/write access to. Required (non-empty) when create_iam_role is true; ignored otherwise. Grant the bucket root ARN (e.g. arn:aws:s3:::my-bucket) even when shares use a prefix. Defaults to []."
  default     = []

  # Deliberately stricter than each share's location_arn: this list builds the IAM policy's
  # Resource elements, where the module appends "/*" for object-level actions, so each entry
  # must be a bucket root ARN with no trailing slash or prefix.
  validation {
    condition = alltrue([
      for arn in var.s3_bucket_arns : can(regex("^arn:[^:]+:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", arn))
    ])
    error_message = "Each s3_bucket_arns entry must be a bucket root ARN with no prefix or trailing slash (e.g. arn:aws:s3:::my-bucket)."
  }
}

variable "iam_name_prefix" {
  type        = string
  description = "(Optional) Name prefix for the IAM role and policy created when create_iam_role is true. A unique suffix is appended. Defaults to storage-gateway-s3-."
  default     = "storage-gateway-s3-"
}

###########################
# CloudWatch Log Group
###########################

variable "create_cloudwatch_log_group" {
  type        = bool
  description = "(Optional) Determines whether this module creates a CloudWatch log group (via the cloudwatch/log_group child module) for gateway health logs and wires it to the gateway. Ignored when cloudwatch_log_group_arn is supplied. Defaults to true."
  default     = true
}

variable "cloudwatch_name_prefix" {
  type        = string
  description = "(Optional) Name prefix for the CloudWatch log group created for gateway health logs. Defaults to /aws/storagegateway/."
  default     = "/aws/storagegateway/"
}

variable "cloudwatch_retention_in_days" {
  type        = number
  description = "(Optional) Number of days to retain gateway log events in the CloudWatch log group. Set to 0 to retain indefinitely. Defaults to 90."
  default     = 90
  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_retention_in_days)
    error_message = "The value of cloudwatch_retention_in_days must be one of the valid CloudWatch log retention periods: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653."
  }
}

###########################
# KMS Encryption Key
###########################

variable "create_kms_key" {
  type        = bool
  description = "(Optional) Determines whether this module creates a dedicated KMS key (via the kms child module) to encrypt the CloudWatch log group. Used only when this module actually creates the log group, so it is ignored both when create_cloudwatch_log_group is false and when cloudwatch_log_group_arn supplies an existing log group (which already carries its own encryption configuration). Set to false to supply your own key via kms_key_id. Defaults to true."
  default     = true
}

variable "kms_key_id" {
  type        = string
  description = "(Optional) ARN of an existing KMS key used to encrypt the CloudWatch log group. Used only when create_kms_key is false. Defaults to null (the log group is unencrypted by a customer-managed key)."
  default     = null

  # CloudWatch Logs requires a key ARN here; an alias or bare key ID is rejected by the API.
  validation {
    condition     = var.kms_key_id == null ? true : can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/.+$", var.kms_key_id))
    error_message = "kms_key_id must be null or a KMS key ARN (arn:<partition>:kms:<region>:<account>:key/<key-id>). CloudWatch Logs does not accept an alias or a bare key ID."
  }
}

variable "kms_key_description" {
  type        = string
  description = "(Optional) The description applied to the KMS key created by this module."
  default     = "KMS key used to encrypt AWS Storage Gateway CloudWatch logs."
}

variable "kms_key_name_prefix" {
  type        = string
  description = "(Optional) Creates a unique KMS alias beginning with the specified prefix. The alias/ prefix is added automatically if omitted."
  default     = "storage_gateway"
}

variable "kms_key_deletion_window_in_days" {
  type        = number
  description = "(Optional) Duration in days after which the KMS key is deleted after destruction of the resource. Must be between 7 and 30 days. Defaults to 30."
  default     = 30
  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "The value of kms_key_deletion_window_in_days must be between 7 and 30 days."
  }
}

variable "kms_key_enable_key_rotation" {
  type        = bool
  description = "(Optional) Specifies whether automatic key rotation is enabled on the KMS key created by this module. Defaults to true."
  default     = true
}
