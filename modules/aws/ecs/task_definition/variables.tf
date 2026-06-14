###########################
# Task Definition Variables
###########################

variable "family" {
  description = "(Required) A unique name for the task definition family. Also used as the `Name` tag value."
  type        = string
}

variable "container_definitions" {
  description = "(Required) A JSON-encoded string of container definitions. This is supplied by the caller; the module does not author container definitions."
  type        = string
}

variable "cpu" {
  description = "(Optional) Number of CPU units used by the task, as a string. Required for Fargate."
  type        = string
  default     = null
}

variable "memory" {
  description = "(Optional) Amount (in MiB) of memory used by the task, as a string. Required for Fargate."
  type        = string
  default     = null
}

variable "network_mode" {
  description = "(Optional) Docker networking mode to use for the containers in the task. Defaults to `awsvpc` (required by Fargate)."
  type        = string
  default     = "awsvpc"
}

variable "requires_compatibilities" {
  description = "(Optional) Set of launch types required by the task. Defaults to `[\"FARGATE\"]`."
  type        = list(string)
  default     = ["FARGATE"]
}

variable "runtime_platform" {
  description = "(Optional) Configuration block for the runtime platform (`operating_system_family` and `cpu_architecture`)."
  type = object({
    operating_system_family = optional(string)
    cpu_architecture        = optional(string)
  })
  default = null
}

variable "ephemeral_storage_size_in_gib" {
  description = "(Optional) The total amount, in GiB, of ephemeral storage to set for the task (21-200). When null, the provider default applies."
  type        = number
  default     = null
}

variable "volumes" {
  description = "(Optional) List of volume definitions for the task. Each entry has a `name` plus optional `host_path`, `configure_at_launch`, `docker_volume_configuration`, `efs_volume_configuration` (transit encryption ENABLED by default), and `fsx_windows_file_server_volume_configuration`."
  type = list(object({
    name                = string
    host_path           = optional(string)
    configure_at_launch = optional(bool)
    docker_volume_configuration = optional(object({
      scope         = optional(string)
      autoprovision = optional(bool)
      driver        = optional(string)
      driver_opts   = optional(map(string))
      labels        = optional(map(string))
    }))
    efs_volume_configuration = optional(object({
      file_system_id          = string
      root_directory          = optional(string)
      transit_encryption      = optional(string, "ENABLED")
      transit_encryption_port = optional(number)
      authorization_config = optional(object({
        access_point_id = optional(string)
        iam             = optional(string)
      }))
    }))
    fsx_windows_file_server_volume_configuration = optional(object({
      file_system_id = string
      root_directory = string
      authorization_config = object({
        credentials_parameter = string
        domain                = string
      })
    }))
  }))
  default = []
}

variable "placement_constraints" {
  description = "(Optional) Rules that are taken into consideration during task placement. Maximum of 10."
  type = list(object({
    type       = string
    expression = optional(string)
  }))
  default = []
}

variable "proxy_configuration" {
  description = "(Optional) Configuration block for the App Mesh proxy."
  type = object({
    type           = optional(string)
    container_name = string
    properties     = optional(map(string))
  })
  default = null
}

variable "ipc_mode" {
  description = "(Optional) IPC resource namespace to be used for the containers in the task. Valid values are `host`, `task`, or `none`."
  type        = string
  default     = null
}

variable "pid_mode" {
  description = "(Optional) Process namespace to use for the containers in the task. Valid values are `host` or `task`."
  type        = string
  default     = null
}

variable "skip_destroy" {
  description = "(Optional) Whether to retain the old revision when the resource is destroyed or task definition is updated. Defaults to false."
  type        = bool
  default     = false
}

variable "track_latest" {
  description = "(Optional) Whether should track latest ACTIVE task definition on AWS or the one created with the resource stored in state."
  type        = bool
  default     = null
}

###########################
# Execution Role Variables
###########################

variable "create_execution_role" {
  description = "(Optional) Whether to create an ECS task execution role (via modules/aws/iam/role). Defaults to true."
  type        = bool
  default     = true
}

variable "execution_role_arn" {
  description = "(Optional) ARN of an existing task execution role. Used when `create_execution_role = false`."
  type        = string
  default     = null
}

variable "execution_role_managed_policy_arns" {
  description = "(Optional) Managed policy ARNs to attach to the created execution role. Defaults to the AWS-managed AmazonECSTaskExecutionRolePolicy."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

###########################
# Task Role Variables
###########################

variable "create_task_role" {
  description = "(Optional) Whether to create a separate ECS task role (via modules/aws/iam/role). Defaults to true for least-privilege separation from the execution role."
  type        = bool
  default     = true
}

variable "task_role_arn" {
  description = "(Optional) ARN of an existing task role. Used when `create_task_role = false`."
  type        = string
  default     = null
}

variable "task_role_policy_json" {
  description = "(Optional) JSON policy document for a least-privilege inline policy attached to the created task role (via modules/aws/iam/policy)."
  type        = string
  default     = null
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) A map of tags to assign to the task definition and the IAM resources created via composition. A `Name` tag is merged automatically."
  type        = map(string)
  default     = {}
}
