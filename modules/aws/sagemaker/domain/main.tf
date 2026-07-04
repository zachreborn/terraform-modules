##############################
# Provider Configuration
##############################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

##############################
# SageMaker Domain
##############################
resource "aws_sagemaker_domain" "this" {
  domain_name                   = var.domain_name
  auth_mode                     = var.auth_mode
  vpc_id                        = var.vpc_id
  subnet_ids                    = var.subnet_ids
  kms_key_id                    = var.kms_key_id
  app_network_access_type       = var.app_network_access_type
  app_security_group_management = var.app_security_group_management
  tag_propagation               = var.tag_propagation
  tags                          = merge(tomap({ Name = var.domain_name }), var.tags)

  default_user_settings {
    auto_mount_home_efs = var.default_user_settings.auto_mount_home_efs
    default_landing_uri = var.default_user_settings.default_landing_uri
    execution_role      = var.default_user_settings.execution_role
    security_groups     = var.default_user_settings.security_groups
    studio_web_portal   = var.default_user_settings.studio_web_portal
    dynamic "canvas_app_settings" {
      for_each = var.default_user_settings.canvas_app_settings != null ? [var.default_user_settings.canvas_app_settings] : []
      content {
        dynamic "direct_deploy_settings" {
          for_each = canvas_app_settings.value.direct_deploy_settings != null ? [canvas_app_settings.value.direct_deploy_settings] : []
          content {
            status = direct_deploy_settings.value.status
          }
        }
        dynamic "emr_serverless_settings" {
          for_each = canvas_app_settings.value.emr_serverless_settings != null ? [canvas_app_settings.value.emr_serverless_settings] : []
          content {
            execution_role_arn = emr_serverless_settings.value.execution_role_arn
            status             = emr_serverless_settings.value.status
          }
        }
        dynamic "generative_ai_settings" {
          for_each = canvas_app_settings.value.generative_ai_settings != null ? [canvas_app_settings.value.generative_ai_settings] : []
          content {
            amazon_bedrock_role_arn = generative_ai_settings.value.amazon_bedrock_role_arn
          }
        }
        dynamic "identity_provider_oauth_settings" {
          for_each = canvas_app_settings.value.identity_provider_oauth_settings != null ? canvas_app_settings.value.identity_provider_oauth_settings : []
          content {
            data_source_name = identity_provider_oauth_settings.value.data_source_name
            secret_arn       = identity_provider_oauth_settings.value.secret_arn
            status           = identity_provider_oauth_settings.value.status
          }
        }
        dynamic "kendra_settings" {
          for_each = canvas_app_settings.value.kendra_settings != null ? [canvas_app_settings.value.kendra_settings] : []
          content {
            status = kendra_settings.value.status
          }
        }
        dynamic "model_register_settings" {
          for_each = canvas_app_settings.value.model_register_settings != null ? [canvas_app_settings.value.model_register_settings] : []
          content {
            cross_account_model_register_role_arn = model_register_settings.value.cross_account_model_register_role_arn
            status                                = model_register_settings.value.status
          }
        }
        dynamic "time_series_forecasting_settings" {
          for_each = canvas_app_settings.value.time_series_forecasting_settings != null ? [canvas_app_settings.value.time_series_forecasting_settings] : []
          content {
            amazon_forecast_role_arn = time_series_forecasting_settings.value.amazon_forecast_role_arn
            status                   = time_series_forecasting_settings.value.status
          }
        }
        dynamic "workspace_settings" {
          for_each = canvas_app_settings.value.workspace_settings != null ? [canvas_app_settings.value.workspace_settings] : []
          content {
            s3_artifact_path = workspace_settings.value.s3_artifact_path
            s3_kms_key_id    = workspace_settings.value.s3_kms_key_id
          }
        }
      }
    }
    dynamic "code_editor_app_settings" {
      for_each = var.default_user_settings.code_editor_app_settings != null ? [var.default_user_settings.code_editor_app_settings] : []
      content {
        built_in_lifecycle_config_arn = code_editor_app_settings.value.built_in_lifecycle_config_arn
        lifecycle_config_arns         = code_editor_app_settings.value.lifecycle_config_arns
        dynamic "app_lifecycle_management" {
          for_each = code_editor_app_settings.value.app_lifecycle_management != null ? [code_editor_app_settings.value.app_lifecycle_management] : []
          content {
            dynamic "idle_settings" {
              for_each = app_lifecycle_management.value.idle_settings != null ? [app_lifecycle_management.value.idle_settings] : []
              content {
                idle_timeout_in_minutes     = idle_settings.value.idle_timeout_in_minutes
                lifecycle_management        = idle_settings.value.lifecycle_management
                max_idle_timeout_in_minutes = idle_settings.value.max_idle_timeout_in_minutes
                min_idle_timeout_in_minutes = idle_settings.value.min_idle_timeout_in_minutes
              }
            }
          }
        }
        dynamic "custom_image" {
          for_each = code_editor_app_settings.value.custom_image != null ? code_editor_app_settings.value.custom_image : []
          content {
            app_image_config_name = custom_image.value.app_image_config_name
            image_name            = custom_image.value.image_name
            image_version_number  = custom_image.value.image_version_number
          }
        }
        dynamic "default_resource_spec" {
          for_each = code_editor_app_settings.value.default_resource_spec != null ? [code_editor_app_settings.value.default_resource_spec] : []
          content {
            instance_type                 = default_resource_spec.value.instance_type
            lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
            sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
            sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
            sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
          }
        }
      }
    }
    dynamic "custom_file_system_config" {
      for_each = var.default_user_settings.custom_file_system_config != null ? var.default_user_settings.custom_file_system_config : []
      content {
        dynamic "efs_file_system_config" {
          for_each = custom_file_system_config.value.efs_file_system_config != null ? [custom_file_system_config.value.efs_file_system_config] : []
          content {
            file_system_id   = efs_file_system_config.value.file_system_id
            file_system_path = efs_file_system_config.value.file_system_path
          }
        }
      }
    }
    dynamic "custom_posix_user_config" {
      for_each = var.default_user_settings.custom_posix_user_config != null ? [var.default_user_settings.custom_posix_user_config] : []
      content {
        gid = custom_posix_user_config.value.gid
        uid = custom_posix_user_config.value.uid
      }
    }
    dynamic "jupyter_lab_app_settings" {
      for_each = var.default_user_settings.jupyter_lab_app_settings != null ? [var.default_user_settings.jupyter_lab_app_settings] : []
      content {
        built_in_lifecycle_config_arn = jupyter_lab_app_settings.value.built_in_lifecycle_config_arn
        lifecycle_config_arns         = jupyter_lab_app_settings.value.lifecycle_config_arns
        dynamic "app_lifecycle_management" {
          for_each = jupyter_lab_app_settings.value.app_lifecycle_management != null ? [jupyter_lab_app_settings.value.app_lifecycle_management] : []
          content {
            dynamic "idle_settings" {
              for_each = app_lifecycle_management.value.idle_settings != null ? [app_lifecycle_management.value.idle_settings] : []
              content {
                idle_timeout_in_minutes     = idle_settings.value.idle_timeout_in_minutes
                lifecycle_management        = idle_settings.value.lifecycle_management
                max_idle_timeout_in_minutes = idle_settings.value.max_idle_timeout_in_minutes
                min_idle_timeout_in_minutes = idle_settings.value.min_idle_timeout_in_minutes
              }
            }
          }
        }
        dynamic "code_repository" {
          for_each = jupyter_lab_app_settings.value.code_repository != null ? jupyter_lab_app_settings.value.code_repository : []
          content {
            repository_url = code_repository.value.repository_url
          }
        }
        dynamic "custom_image" {
          for_each = jupyter_lab_app_settings.value.custom_image != null ? jupyter_lab_app_settings.value.custom_image : []
          content {
            app_image_config_name = custom_image.value.app_image_config_name
            image_name            = custom_image.value.image_name
            image_version_number  = custom_image.value.image_version_number
          }
        }
        dynamic "default_resource_spec" {
          for_each = jupyter_lab_app_settings.value.default_resource_spec != null ? [jupyter_lab_app_settings.value.default_resource_spec] : []
          content {
            instance_type                 = default_resource_spec.value.instance_type
            lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
            sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
            sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
            sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
          }
        }
        dynamic "emr_settings" {
          for_each = jupyter_lab_app_settings.value.emr_settings != null ? [jupyter_lab_app_settings.value.emr_settings] : []
          content {
            assumable_role_arns = emr_settings.value.assumable_role_arns
            execution_role_arns = emr_settings.value.execution_role_arns
          }
        }
      }
    }
    dynamic "jupyter_server_app_settings" {
      for_each = var.default_user_settings.jupyter_server_app_settings != null ? [var.default_user_settings.jupyter_server_app_settings] : []
      content {
        lifecycle_config_arns = jupyter_server_app_settings.value.lifecycle_config_arns
        dynamic "code_repository" {
          for_each = jupyter_server_app_settings.value.code_repository != null ? jupyter_server_app_settings.value.code_repository : []
          content {
            repository_url = code_repository.value.repository_url
          }
        }
        dynamic "default_resource_spec" {
          for_each = jupyter_server_app_settings.value.default_resource_spec != null ? [jupyter_server_app_settings.value.default_resource_spec] : []
          content {
            instance_type                 = default_resource_spec.value.instance_type
            lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
            sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
            sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
            sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
          }
        }
      }
    }
    dynamic "kernel_gateway_app_settings" {
      for_each = var.default_user_settings.kernel_gateway_app_settings != null ? [var.default_user_settings.kernel_gateway_app_settings] : []
      content {
        lifecycle_config_arns = kernel_gateway_app_settings.value.lifecycle_config_arns
        dynamic "custom_image" {
          for_each = kernel_gateway_app_settings.value.custom_image != null ? kernel_gateway_app_settings.value.custom_image : []
          content {
            app_image_config_name = custom_image.value.app_image_config_name
            image_name            = custom_image.value.image_name
            image_version_number  = custom_image.value.image_version_number
          }
        }
        dynamic "default_resource_spec" {
          for_each = kernel_gateway_app_settings.value.default_resource_spec != null ? [kernel_gateway_app_settings.value.default_resource_spec] : []
          content {
            instance_type                 = default_resource_spec.value.instance_type
            lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
            sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
            sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
            sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
          }
        }
      }
    }
    dynamic "r_session_app_settings" {
      for_each = var.default_user_settings.r_session_app_settings != null ? [var.default_user_settings.r_session_app_settings] : []
      content {
        dynamic "custom_image" {
          for_each = r_session_app_settings.value.custom_image != null ? r_session_app_settings.value.custom_image : []
          content {
            app_image_config_name = custom_image.value.app_image_config_name
            image_name            = custom_image.value.image_name
            image_version_number  = custom_image.value.image_version_number
          }
        }
        dynamic "default_resource_spec" {
          for_each = r_session_app_settings.value.default_resource_spec != null ? [r_session_app_settings.value.default_resource_spec] : []
          content {
            instance_type                 = default_resource_spec.value.instance_type
            lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
            sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
            sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
            sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
          }
        }
      }
    }
    dynamic "r_studio_server_pro_app_settings" {
      for_each = var.default_user_settings.r_studio_server_pro_app_settings != null ? [var.default_user_settings.r_studio_server_pro_app_settings] : []
      content {
        access_status = r_studio_server_pro_app_settings.value.access_status
        user_group    = r_studio_server_pro_app_settings.value.user_group
      }
    }
    dynamic "sharing_settings" {
      for_each = var.default_user_settings.sharing_settings != null ? [var.default_user_settings.sharing_settings] : []
      content {
        notebook_output_option = sharing_settings.value.notebook_output_option
        s3_kms_key_id          = sharing_settings.value.s3_kms_key_id
        s3_output_path         = sharing_settings.value.s3_output_path
      }
    }
    dynamic "space_storage_settings" {
      for_each = var.default_user_settings.space_storage_settings != null ? [var.default_user_settings.space_storage_settings] : []
      content {
        dynamic "default_ebs_storage_settings" {
          for_each = space_storage_settings.value.default_ebs_storage_settings != null ? [space_storage_settings.value.default_ebs_storage_settings] : []
          content {
            default_ebs_volume_size_in_gb = default_ebs_storage_settings.value.default_ebs_volume_size_in_gb
            maximum_ebs_volume_size_in_gb = default_ebs_storage_settings.value.maximum_ebs_volume_size_in_gb
          }
        }
      }
    }
    dynamic "studio_web_portal_settings" {
      for_each = var.default_user_settings.studio_web_portal_settings != null ? [var.default_user_settings.studio_web_portal_settings] : []
      content {
        hidden_app_types      = studio_web_portal_settings.value.hidden_app_types
        hidden_instance_types = studio_web_portal_settings.value.hidden_instance_types
        hidden_ml_tools       = studio_web_portal_settings.value.hidden_ml_tools
      }
    }
    dynamic "tensor_board_app_settings" {
      for_each = var.default_user_settings.tensor_board_app_settings != null ? [var.default_user_settings.tensor_board_app_settings] : []
      content {
        dynamic "default_resource_spec" {
          for_each = tensor_board_app_settings.value.default_resource_spec != null ? [tensor_board_app_settings.value.default_resource_spec] : []
          content {
            instance_type                 = default_resource_spec.value.instance_type
            lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
            sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
            sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
            sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
          }
        }
      }
    }
  }

  dynamic "default_space_settings" {
    for_each = var.default_space_settings != null ? [var.default_space_settings] : []
    content {
      execution_role  = default_space_settings.value.execution_role
      security_groups = default_space_settings.value.security_groups
      dynamic "custom_file_system_config" {
        for_each = default_space_settings.value.custom_file_system_config != null ? default_space_settings.value.custom_file_system_config : []
        content {
          dynamic "efs_file_system_config" {
            for_each = custom_file_system_config.value.efs_file_system_config != null ? [custom_file_system_config.value.efs_file_system_config] : []
            content {
              file_system_id   = efs_file_system_config.value.file_system_id
              file_system_path = efs_file_system_config.value.file_system_path
            }
          }
        }
      }
      dynamic "custom_posix_user_config" {
        for_each = default_space_settings.value.custom_posix_user_config != null ? [default_space_settings.value.custom_posix_user_config] : []
        content {
          gid = custom_posix_user_config.value.gid
          uid = custom_posix_user_config.value.uid
        }
      }
      dynamic "jupyter_lab_app_settings" {
        for_each = default_space_settings.value.jupyter_lab_app_settings != null ? [default_space_settings.value.jupyter_lab_app_settings] : []
        content {
          built_in_lifecycle_config_arn = jupyter_lab_app_settings.value.built_in_lifecycle_config_arn
          lifecycle_config_arns         = jupyter_lab_app_settings.value.lifecycle_config_arns
          dynamic "app_lifecycle_management" {
            for_each = jupyter_lab_app_settings.value.app_lifecycle_management != null ? [jupyter_lab_app_settings.value.app_lifecycle_management] : []
            content {
              dynamic "idle_settings" {
                for_each = app_lifecycle_management.value.idle_settings != null ? [app_lifecycle_management.value.idle_settings] : []
                content {
                  idle_timeout_in_minutes     = idle_settings.value.idle_timeout_in_minutes
                  lifecycle_management        = idle_settings.value.lifecycle_management
                  max_idle_timeout_in_minutes = idle_settings.value.max_idle_timeout_in_minutes
                  min_idle_timeout_in_minutes = idle_settings.value.min_idle_timeout_in_minutes
                }
              }
            }
          }
          dynamic "code_repository" {
            for_each = jupyter_lab_app_settings.value.code_repository != null ? jupyter_lab_app_settings.value.code_repository : []
            content {
              repository_url = code_repository.value.repository_url
            }
          }
          dynamic "custom_image" {
            for_each = jupyter_lab_app_settings.value.custom_image != null ? jupyter_lab_app_settings.value.custom_image : []
            content {
              app_image_config_name = custom_image.value.app_image_config_name
              image_name            = custom_image.value.image_name
              image_version_number  = custom_image.value.image_version_number
            }
          }
          dynamic "default_resource_spec" {
            for_each = jupyter_lab_app_settings.value.default_resource_spec != null ? [jupyter_lab_app_settings.value.default_resource_spec] : []
            content {
              instance_type                 = default_resource_spec.value.instance_type
              lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
              sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
              sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
              sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
            }
          }
          dynamic "emr_settings" {
            for_each = jupyter_lab_app_settings.value.emr_settings != null ? [jupyter_lab_app_settings.value.emr_settings] : []
            content {
              assumable_role_arns = emr_settings.value.assumable_role_arns
              execution_role_arns = emr_settings.value.execution_role_arns
            }
          }
        }
      }
      dynamic "jupyter_server_app_settings" {
        for_each = default_space_settings.value.jupyter_server_app_settings != null ? [default_space_settings.value.jupyter_server_app_settings] : []
        content {
          lifecycle_config_arns = jupyter_server_app_settings.value.lifecycle_config_arns
          dynamic "code_repository" {
            for_each = jupyter_server_app_settings.value.code_repository != null ? jupyter_server_app_settings.value.code_repository : []
            content {
              repository_url = code_repository.value.repository_url
            }
          }
          dynamic "default_resource_spec" {
            for_each = jupyter_server_app_settings.value.default_resource_spec != null ? [jupyter_server_app_settings.value.default_resource_spec] : []
            content {
              instance_type                 = default_resource_spec.value.instance_type
              lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
              sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
              sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
              sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
            }
          }
        }
      }
      dynamic "kernel_gateway_app_settings" {
        for_each = default_space_settings.value.kernel_gateway_app_settings != null ? [default_space_settings.value.kernel_gateway_app_settings] : []
        content {
          lifecycle_config_arns = kernel_gateway_app_settings.value.lifecycle_config_arns
          dynamic "custom_image" {
            for_each = kernel_gateway_app_settings.value.custom_image != null ? kernel_gateway_app_settings.value.custom_image : []
            content {
              app_image_config_name = custom_image.value.app_image_config_name
              image_name            = custom_image.value.image_name
              image_version_number  = custom_image.value.image_version_number
            }
          }
          dynamic "default_resource_spec" {
            for_each = kernel_gateway_app_settings.value.default_resource_spec != null ? [kernel_gateway_app_settings.value.default_resource_spec] : []
            content {
              instance_type                 = default_resource_spec.value.instance_type
              lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
              sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
              sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
              sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
            }
          }
        }
      }
      dynamic "space_storage_settings" {
        for_each = default_space_settings.value.space_storage_settings != null ? [default_space_settings.value.space_storage_settings] : []
        content {
          dynamic "default_ebs_storage_settings" {
            for_each = space_storage_settings.value.default_ebs_storage_settings != null ? [space_storage_settings.value.default_ebs_storage_settings] : []
            content {
              default_ebs_volume_size_in_gb = default_ebs_storage_settings.value.default_ebs_volume_size_in_gb
              maximum_ebs_volume_size_in_gb = default_ebs_storage_settings.value.maximum_ebs_volume_size_in_gb
            }
          }
        }
      }
    }
  }

  dynamic "domain_settings" {
    for_each = var.domain_settings != null ? [var.domain_settings] : []
    content {
      execution_role_identity_config = domain_settings.value.execution_role_identity_config
      security_group_ids             = domain_settings.value.security_group_ids
      dynamic "docker_settings" {
        for_each = domain_settings.value.docker_settings != null ? [domain_settings.value.docker_settings] : []
        content {
          enable_docker_access      = docker_settings.value.enable_docker_access
          vpc_only_trusted_accounts = docker_settings.value.vpc_only_trusted_accounts
        }
      }
      dynamic "r_studio_server_pro_domain_settings" {
        for_each = domain_settings.value.r_studio_server_pro_domain_settings != null ? [domain_settings.value.r_studio_server_pro_domain_settings] : []
        content {
          domain_execution_role_arn    = r_studio_server_pro_domain_settings.value.domain_execution_role_arn
          r_studio_connect_url         = r_studio_server_pro_domain_settings.value.r_studio_connect_url
          r_studio_package_manager_url = r_studio_server_pro_domain_settings.value.r_studio_package_manager_url
          dynamic "default_resource_spec" {
            for_each = r_studio_server_pro_domain_settings.value.default_resource_spec != null ? [r_studio_server_pro_domain_settings.value.default_resource_spec] : []
            content {
              instance_type                 = default_resource_spec.value.instance_type
              lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
              sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
              sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
              sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
            }
          }
        }
      }
      dynamic "trusted_identity_propagation_settings" {
        for_each = domain_settings.value.trusted_identity_propagation_settings != null ? [domain_settings.value.trusted_identity_propagation_settings] : []
        content {
          status = trusted_identity_propagation_settings.value.status
        }
      }
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy != null ? [var.retention_policy] : []
    content {
      home_efs_file_system = retention_policy.value.home_efs_file_system
    }
  }
}
