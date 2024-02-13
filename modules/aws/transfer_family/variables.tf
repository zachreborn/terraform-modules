###########################
# Cloudwatch Log Group Variables
###########################

###########################
# Transfer Server Variables
###########################

variable "address_allocation_ids" {
  description = "(Optional) A list of address allocation IDs that are required to attach an Elastic IP address to your server's endpoint. This can only be set when 'var.endpoint_type' is set to 'VPC'"
  type        = list(string)
  default     = []
}

variable "as2_transports" {
  description = "(Optional) The transport method for AS2 messages. Valid values are HTTP."
  type        = list(string)
  default     = null
  validation {
    condition     = var.as2_transports == null ? true : can(regex("^(HTTP)$", var.as2_transports))
    error_message = "The value of as2_transports must be either null, or HTTP."
  }
}

variable "certificate" {
  description = "(Optional) The ARN of the AWS Certificate Manager certificate to use with the server"
  type        = string
  default     = null
}

variable "directory_id" {
  description = "(Optional) The ID of the AWS Directory Service directory that you want to associate with the server"
  type        = string
  default     = null
}

variable "endpoint_type" {
  description = "(Optional) The type of endpoint that you want your server to use. Valid values are VPC and PUBLIC"
  type        = string
  default     = "PUBLIC"
}

variable "function" {
  description = "(Optional) The ARN of the AWS Lambda function that is invoked for user authentication"
  type        = string
  default     = null
}

variable "host_key" {
  description = "(Optional) The RSA, ECDSA, or ED25519 private key. This must be created ahead of time."
  type        = string
  default     = null
}

variable "identity_provider_type" {
  description = "(Optional) The mode of authentication enabled for this service. Valid values are SERVICE_MANAGED or API_GATEWAY"
  type        = string
  default     = "SERVICE_MANAGED"
  validation {
    condition     = can(regex("^(SERVICE_MANAGED|API_GATEWAY)$", var.identity_provider_type))
    error_message = "The value of identity_provider_type must be either SERVICE_MANAGED or API_GATEWAY."
  }
}

variable "invocation_role" {
  description = "(Optional) The ARN of the IAM role that controls your authentication with an identity provider_type through API_GATEWAY."
  type        = string
  default     = null
}

variable "logging_role" {
  description = "(Optional) The ARN of the IAM role that allows the service to write your server access logs to a Amazon CloudWatch log group."
  type        = string
  default     = null
}

variable "on_partial_upload" {
  description = "(Optional) The ARN of the AWS Lambda function that is invoked after partial uploads."
  type        = string
  default     = null
}

variable "on_upload" {
  description = "(Optional) The ARN of the AWS Lambda function that is invoked after a file is uploaded."
  type        = string
  default     = null
}

variable "passive_ip" {
  description = "(Optional) Sets passive mode for FTP and FTPS protocols and the associated IPv4 address to associate."
  type        = string
  default     = null
}

variable "pre_authentication_login_banner" {
  description = "(Optional) The banner message which is displayed to users before they authenticate to the server."
  type        = string
  default     = null
}

variable "post_authentication_login_banner" {
  description = "(Optional) The banner message which is displayed to users after they authenticate to the server."
  type        = string
  default     = null
}

variable "protocols" {
  description = "(Optional) The list of protocol settings that are configured for your server. Valid values are AS2, SFTP, FTP, and FTPS."
  type        = list(string)
  default     = ["SFTP"]
  validation {
    condition     = can(regex("^(AS2|SFTP|FTP|FTPS)$", var.protocols))
    error_message = "The value of protocols must be either AS2, SFTP, FTP, or FTPS."
  }
}

variable "security_group_ids" {
  description = "(Optional) A list of security group IDs that are attached to the server's endpoint. (Optional) A list of security groups IDs that are available to attach to your server's endpoint. If no security groups are specified, the VPC's default security groups are automatically assigned to your endpoint. This property can only be used when endpoint_type is set to VPC."
  type        = list(string)
  default     = []
}

variable "security_policy_name" {
  description = "(Optional) Specifies the name of the security policy that is attached to the server.  Possible values are TransferSecurityPolicy-2018-11, TransferSecurityPolicy-2020-06, TransferSecurityPolicy-FIPS-2020-06, TransferSecurityPolicy-FIPS-2023-05, TransferSecurityPolicy-2022-03, TransferSecurityPolicy-2023-05, TransferSecurityPolicy-PQ-SSH-Experimental-2023-04, TransferSecurityPolicy-2024-01, and TransferSecurityPolicy-PQ-SSH-FIPS-Experimental-2023-04. Default value is: TransferSecurityPolicy-2024-01."
  type        = string
  default     = "TransferSecurityPolicy-2024-01"
  validation {
    condition     = can(regex("^(TransferSecurityPolicy-2018-11|TransferSecurityPolicy-2020-06|TransferSecurityPolicy-FIPS-2020-06|TransferSecurityPolicy-FIPS-2023-05|TransferSecurityPolicy-2022-03|TransferSecurityPolicy-2023-05|TransferSecurityPolicy-2024-01|TransferSecurityPolicy-PQ-SSH-Experimental-2023-04|TransferSecurityPolicy-PQ-SSH-FIPS-Experimental-2023-04)$", var.security_policy_name))
    error_message = "The value of security_policy_name must be one of the following: TransferSecurityPolicy-2018-11, TransferSecurityPolicy-2020-06, TransferSecurityPolicy-FIPS-2020-06, TransferSecurityPolicy-FIPS-2023-05, TransferSecurityPolicy-2022-03, TransferSecurityPolicy-2023-05, TransferSecurityPolicy-PQ-SSH-Experimental-2023-04, TransferSecurityPolicy-PQ-SSH-FIPS-Experimental-2023-04."
  }
}

variable "set_stat_option" {
  description = "(Optional) Specifies the behavior of your server endpoint when you use the STAT command. Valid values are: DEFAULT and ENABLE_NO_OP."
  type        = string
  default     = null
  validation {
    condition     = var.set_stat_option == null ? true : can(regex("^(DEFAULT|ENABLE_NO_OP)$", var.set_stat_option))
    error_message = "The value of set_stat_option must be either null, DEFAULT, or ENABLE_NO_OP."
  }
}

variable "storage_location" {
  description = "(Optional) The domain of the storage system that is used for file transfers. Valid values are: S3 and EFS. The default is S3."
  type        = string
  default     = "S3"
  validation {
    condition     = can(regex("^(S3|EFS)$", var.storage_location))
    error_message = "The value of storage_location must be either S3 or EFS."
  }
}

variable "subnet_ids" {
  description = "(Optional) A list of subnet IDs that are required to host your server endpoint in your VPC. This property can only be used when endpoint_type is set to VPC."
  type        = list(string)
  default     = []
}

variable "tls_session_resumption_mode" {
  description = "(Optional) Specifies the mode of the TLS session resumption. Valid values are: DISABLED, ENABLED, and ENFORCED."
  type        = string
  default     = null
  validation {
    condition     = var.tls_session_resumption_mode == null ? true : can(regex("^(DISABLED|ENABLED|ENFORCED)$", var.tls_session_resumption_mode))
    error_message = "The value of tls_session_resumption_mode must be either null, DISABLED, ENABLED, or ENFORCED."
  }
}

variable "url" {
  description = "(Optional) The URL of the file transfer protocol endpoint that is used to authentication users through an API_GATEWAY."
  type        = string
  default     = null
}

variable "vpc_endpoint_id" {
  description = "(Optional) The ID of the VPC endpoint. This property can only be used when endpoint_type is set to VPC."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "(Optional) The ID of the VPC that is used for the transfer server. This property can only be used when endpoint_type is set to VPC."
  type        = string
  default     = null
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) Key-value mapping of resource tags"
  type        = map(string)
  default = {
    terraform = "true"
  }
}
