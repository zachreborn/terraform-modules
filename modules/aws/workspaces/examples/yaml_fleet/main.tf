terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Locals
###########################

locals {
  ip_groups   = yamldecode(file("${path.module}/ip_groups.yaml"))
  directories = yamldecode(file("${path.module}/directories.yaml"))
  fleet       = yamldecode(file("${path.module}/users.yaml"))

  # Expand each group's flat usernames list into the full `workspaces` map the module needs -- one entry
  # per user, keyed by "<directory_key>-<username>" so usernames only need to be unique within their own
  # group. This is the piece that lets the YAML stay small (a handful of groups) while the resulting
  # desktop fleet scales to however many usernames each group lists -- adding the 1,000th user is exactly
  # as simple as adding the 1st.
  workspaces = merge([
    for group in local.fleet.groups : {
      for username in group.usernames : "${group.directory_key}-${username}" => {
        directory_key = group.directory_key
        user_name     = username
        bundle_name   = group.bundle_name
      }
    }
  ]...)
}

###########################
# WorkSpaces Fleet
###########################

module "workspaces" {
  source = "../.."

  ip_groups   = local.ip_groups
  directories = local.directories
  workspaces  = local.workspaces

  tags = {
    terraform = "true"
    team      = "it"
  }
}

###########################
# Outputs
###########################

output "directory_ids" {
  description = "Map of WorkSpaces directory IDs, keyed by the same keys as directories.yaml."
  value       = module.workspaces.directory_ids
}

output "workspace_ids" {
  description = "Map of WorkSpaces desktop IDs, keyed by \"<directory_key>-<username>\"."
  value       = module.workspaces.workspace_ids
}
