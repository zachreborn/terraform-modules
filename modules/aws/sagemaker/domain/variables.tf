###########################
# Domain Variables
###########################

variable "domain_name" {
  type        = string
  description = "(Required) The domain name."
}

variable "auth_mode" {
  type        = string
  description = "(Required) The mode of authentication that members use to access the domain. Valid values are IAM and SSO."
  validation {
    condition     = contains(["IAM", "SSO"], var.auth_mode)
    error_message = "auth_mode must be IAM or SSO."
  }
}

variable "vpc_id" {
  type        = string
  description = "(Required) The ID of the Amazon Virtual Private Cloud (VPC) that the domain uses for communication."
}

variable "subnet_ids" {
  type        = list(string)
  description = "(Required) The VPC subnets that the domain uses for communication."
}

variable "kms_key_id" {
  type        = string
  description = "(Optional) The AWS KMS customer managed key (CMK) used to encrypt the EFS volume attached to the domain. If null, an AWS managed key is used."
  default     = null
}

variable "app_network_access_type" {
  type        = string
  description = "(Optional) Specifies the VPC used for non-EFS traffic. Valid values are PublicInternetOnly and VpcOnly. Defaults to VpcOnly for a secure-by-default posture (the provider default is PublicInternetOnly)."
  default     = "VpcOnly"
  validation {
    condition     = contains(["PublicInternetOnly", "VpcOnly"], var.app_network_access_type)
    error_message = "app_network_access_type must be PublicInternetOnly or VpcOnly."
  }
}

variable "app_security_group_management" {
  type        = string
  description = "(Optional) The entity that creates and manages the required security groups for inter-app communication in VPCOnly mode. Valid values are Service and Customer."
  default     = null
  validation {
    condition     = var.app_security_group_management == null ? true : contains(["Service", "Customer"], var.app_security_group_management)
    error_message = "app_security_group_management must be Service, Customer, or null."
  }
}

variable "tag_propagation" {
  type        = string
  description = "(Optional) Indicates whether custom tag propagation is supported for the domain. Valid values are ENABLED and DISABLED. Defaults to DISABLED."
  default     = "DISABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.tag_propagation)
    error_message = "tag_propagation must be ENABLED or DISABLED."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Map of tags to assign to the resource."
  default     = {}
}

###########################
# Nested Block Variables
###########################

variable "default_user_settings" {
  type = object({
    auto_mount_home_efs = optional(string)
    default_landing_uri = optional(string)
    execution_role      = string
    security_groups     = optional(list(string))
    studio_web_portal   = optional(string)
    canvas_app_settings = optional(object({
      direct_deploy_settings = optional(object({
        status = optional(string)
      }))
      emr_serverless_settings = optional(object({
        execution_role_arn = optional(string)
        status             = optional(string)
      }))
      generative_ai_settings = optional(object({
        amazon_bedrock_role_arn = optional(string)
      }))
      identity_provider_oauth_settings = optional(list(object({
        data_source_name = optional(string)
        secret_arn       = string
        status           = optional(string)
      })))
      kendra_settings = optional(object({
        status = optional(string)
      }))
      model_register_settings = optional(object({
        cross_account_model_register_role_arn = optional(string)
        status                                = optional(string)
      }))
      time_series_forecasting_settings = optional(object({
        amazon_forecast_role_arn = optional(string)
        status                   = optional(string)
      }))
      workspace_settings = optional(object({
        s3_artifact_path = optional(string)
        s3_kms_key_id    = optional(string)
      }))
    }))
    code_editor_app_settings = optional(object({
      built_in_lifecycle_config_arn = optional(string)
      lifecycle_config_arns         = optional(list(string))
      app_lifecycle_management = optional(object({
        idle_settings = optional(object({
          idle_timeout_in_minutes     = optional(number)
          lifecycle_management        = optional(string)
          max_idle_timeout_in_minutes = optional(number)
          min_idle_timeout_in_minutes = optional(number)
        }))
      }))
      custom_image = optional(list(object({
        app_image_config_name = string
        image_name            = string
        image_version_number  = optional(number)
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
    custom_file_system_config = optional(list(object({
      efs_file_system_config = optional(object({
        file_system_id   = string
        file_system_path = string
      }))
    })))
    custom_posix_user_config = optional(object({
      gid = number
      uid = number
    }))
    jupyter_lab_app_settings = optional(object({
      built_in_lifecycle_config_arn = optional(string)
      lifecycle_config_arns         = optional(list(string))
      app_lifecycle_management = optional(object({
        idle_settings = optional(object({
          idle_timeout_in_minutes     = optional(number)
          lifecycle_management        = optional(string)
          max_idle_timeout_in_minutes = optional(number)
          min_idle_timeout_in_minutes = optional(number)
        }))
      }))
      code_repository = optional(list(object({
        repository_url = string
      })))
      custom_image = optional(list(object({
        app_image_config_name = string
        image_name            = string
        image_version_number  = optional(number)
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
      emr_settings = optional(object({
        assumable_role_arns = optional(list(string))
        execution_role_arns = optional(list(string))
      }))
    }))
    jupyter_server_app_settings = optional(object({
      lifecycle_config_arns = optional(list(string))
      code_repository = optional(list(object({
        repository_url = string
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
    kernel_gateway_app_settings = optional(object({
      lifecycle_config_arns = optional(list(string))
      custom_image = optional(list(object({
        app_image_config_name = string
        image_name            = string
        image_version_number  = optional(number)
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
    r_session_app_settings = optional(object({
      custom_image = optional(list(object({
        app_image_config_name = string
        image_name            = string
        image_version_number  = optional(number)
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
    r_studio_server_pro_app_settings = optional(object({
      access_status = optional(string)
      user_group    = optional(string)
    }))
    sharing_settings = optional(object({
      notebook_output_option = optional(string)
      s3_kms_key_id          = optional(string)
      s3_output_path         = optional(string)
    }))
    space_storage_settings = optional(object({
      default_ebs_storage_settings = optional(object({
        default_ebs_volume_size_in_gb = number
        maximum_ebs_volume_size_in_gb = number
      }))
    }))
    studio_web_portal_settings = optional(object({
      hidden_app_types      = optional(list(string))
      hidden_instance_types = optional(list(string))
      hidden_ml_tools       = optional(list(string))
    }))
    tensor_board_app_settings = optional(object({
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
  })
  description = "(Required) The default user settings applied to the domain. Must include execution_role; all app-settings sub-blocks are optional and map directly to the aws_sagemaker_domain default_user_settings block."
}

variable "default_space_settings" {
  type = object({
    execution_role  = string
    security_groups = optional(list(string))
    custom_file_system_config = optional(list(object({
      efs_file_system_config = optional(object({
        file_system_id   = string
        file_system_path = string
      }))
    })))
    custom_posix_user_config = optional(object({
      gid = number
      uid = number
    }))
    jupyter_lab_app_settings = optional(object({
      built_in_lifecycle_config_arn = optional(string)
      lifecycle_config_arns         = optional(list(string))
      app_lifecycle_management = optional(object({
        idle_settings = optional(object({
          idle_timeout_in_minutes     = optional(number)
          lifecycle_management        = optional(string)
          max_idle_timeout_in_minutes = optional(number)
          min_idle_timeout_in_minutes = optional(number)
        }))
      }))
      code_repository = optional(list(object({
        repository_url = string
      })))
      custom_image = optional(list(object({
        app_image_config_name = string
        image_name            = string
        image_version_number  = optional(number)
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
      emr_settings = optional(object({
        assumable_role_arns = optional(list(string))
        execution_role_arns = optional(list(string))
      }))
    }))
    jupyter_server_app_settings = optional(object({
      lifecycle_config_arns = optional(list(string))
      code_repository = optional(list(object({
        repository_url = string
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
    kernel_gateway_app_settings = optional(object({
      lifecycle_config_arns = optional(list(string))
      custom_image = optional(list(object({
        app_image_config_name = string
        image_name            = string
        image_version_number  = optional(number)
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
    space_storage_settings = optional(object({
      default_ebs_storage_settings = optional(object({
        default_ebs_volume_size_in_gb = number
        maximum_ebs_volume_size_in_gb = number
      }))
    }))
  })
  description = "(Optional) The default settings for shared spaces created in the domain. Must include execution_role when set."
  default     = null
}

variable "domain_settings" {
  type = object({
    execution_role_identity_config = optional(string)
    security_group_ids             = optional(list(string))
    docker_settings = optional(object({
      enable_docker_access      = optional(string)
      vpc_only_trusted_accounts = optional(list(string))
    }))
    r_studio_server_pro_domain_settings = optional(object({
      domain_execution_role_arn    = string
      r_studio_connect_url         = optional(string)
      r_studio_package_manager_url = optional(string)
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
    trusted_identity_propagation_settings = optional(object({
      status = string
    }))
  })
  description = "(Optional) Domain-level settings such as the execution role identity config, domain-boundary security groups, Docker access, and RStudio server settings."
  default     = null
}

variable "retention_policy" {
  type = object({
    home_efs_file_system = optional(string)
  })
  description = "(Optional) The retention policy for data stored on the domain EFS volume. Set home_efs_file_system to Retain or Delete."
  default     = null
  validation {
    condition     = try(var.retention_policy.home_efs_file_system, null) == null ? true : contains(["Retain", "Delete"], var.retention_policy.home_efs_file_system)
    error_message = "retention_policy.home_efs_file_system must be Retain or Delete."
  }
}
