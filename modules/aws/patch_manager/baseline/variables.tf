###########################
# Patch Baseline Variables
###########################

variable "name" {
  description = "(Required) The name of the patch baseline."
  type        = string
}

variable "description" {
  description = "(Optional) The description of the patch baseline."
  type        = string
  default     = null
}

variable "operating_system" {
  description = "(Required) The operating system family for the patch baseline. Valid values: AMAZON_LINUX, AMAZON_LINUX_2, AMAZON_LINUX_2022, AMAZON_LINUX_2023, CENTOS, DEBIAN, ORACLE_LINUX, RASPBIAN, REDHAT_ENTERPRISE_LINUX, ROCKY_LINUX, SUSE, UBUNTU."
  type        = string
  validation {
    condition = contains([
      "AMAZON_LINUX",
      "AMAZON_LINUX_2",
      "AMAZON_LINUX_2022",
      "AMAZON_LINUX_2023",
      "CENTOS",
      "DEBIAN",
      "ORACLE_LINUX",
      "RASPBIAN",
      "REDHAT_ENTERPRISE_LINUX",
      "ROCKY_LINUX",
      "SUSE",
      "UBUNTU",
    ], var.operating_system)
    error_message = "operating_system must be one of: AMAZON_LINUX, AMAZON_LINUX_2, AMAZON_LINUX_2022, AMAZON_LINUX_2023, CENTOS, DEBIAN, ORACLE_LINUX, RASPBIAN, REDHAT_ENTERPRISE_LINUX, ROCKY_LINUX, SUSE, UBUNTU."
  }
}

variable "global_filters" {
  description = "(Optional) List of global patch filters applied before any approval rules. Filters patches out before rules are evaluated. Note: valid filter keys differ by operating system."
  type = list(object({
    key    = string
    values = list(string)
  }))
  default = []
}

variable "approval_rules" {
  description = "(Optional) List of approval rule configurations for the patch baseline. Each rule specifies patch filters and approval settings. Note: valid patch filter keys differ by OS. For Amazon Linux and RHEL-family use CLASSIFICATION and SEVERITY. For Ubuntu/Debian use PRIORITY. For SUSE use CLASSIFICATION and SEVERITY."
  type = list(object({
    approve_after_days  = number
    approve_until_date  = string
    compliance_level    = string
    enable_non_security = bool
    patch_filters = list(object({
      key    = string
      values = list(string)
    }))
  }))
  default = [
    {
      approve_after_days  = 10
      approve_until_date  = null
      compliance_level    = "UNSPECIFIED"
      enable_non_security = true
      patch_filters = [
        {
          key    = "CLASSIFICATION"
          values = ["Security", "Bugfix", "Enhancement", "Recommended", "Newpackage"]
        },
        {
          key    = "SEVERITY"
          values = ["Critical", "Important", "Medium", "Low"]
        },
      ]
    },
  ]
}

variable "approved_patches" {
  description = "(Optional) List of explicitly approved patch names or KB numbers to include regardless of the approval rules."
  type        = list(string)
  default     = []
}

variable "approved_patches_compliance_level" {
  description = "(Optional) Compliance level for approved patches. Valid values: CRITICAL, HIGH, MEDIUM, LOW, INFORMATIONAL, UNSPECIFIED."
  type        = string
  default     = "UNSPECIFIED"
  validation {
    condition     = contains(["CRITICAL", "HIGH", "MEDIUM", "LOW", "INFORMATIONAL", "UNSPECIFIED"], var.approved_patches_compliance_level)
    error_message = "approved_patches_compliance_level must be one of: CRITICAL, HIGH, MEDIUM, LOW, INFORMATIONAL, UNSPECIFIED."
  }
}

variable "rejected_patches" {
  description = "(Optional) List of explicitly rejected patch names or KB numbers to exclude regardless of the approval rules."
  type        = list(string)
  default     = []
}

variable "rejected_patches_action" {
  description = "(Optional) The action for Patch Manager to take on patches included in the rejected_patches list. Valid values: ALLOW_AS_DEPENDENCY, BLOCK."
  type        = string
  default     = "BLOCK"
  validation {
    condition     = contains(["ALLOW_AS_DEPENDENCY", "BLOCK"], var.rejected_patches_action)
    error_message = "rejected_patches_action must be either ALLOW_AS_DEPENDENCY or BLOCK."
  }
}

variable "sources" {
  description = "(Optional) List of custom patch repository configurations. Useful for RHEL, CentOS, and SUSE to specify additional or alternative package repositories."
  type = list(object({
    name          = string
    products      = list(string)
    configuration = string
  }))
  default = []
}

variable "set_as_default_baseline" {
  description = "(Optional) Whether to override the AWS-managed default patch baseline for this operating system. When true, instances of this OS family without a Patch Group tag will use this baseline."
  type        = bool
  default     = false
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) Map of tags to assign to the resource."
  type        = map(any)
  default = {
    created_by  = "terraform"
    terraform   = "true"
    environment = "prod"
  }
}
