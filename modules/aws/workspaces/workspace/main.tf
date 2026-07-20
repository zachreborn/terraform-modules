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
  # Distinct (bundle_name, bundle_owner) pairs across every entry that needs a lookup (bundle_id == null),
  # rather than one lookup per entry. Scaling to thousands of desktops typically means thousands of entries
  # sharing only a handful of distinct bundles (e.g. one Windows bundle and one Linux bundle), so keying the
  # data source by the distinct pair -- instead of by each entry's own map key -- turns what would otherwise
  # be thousands of redundant data source reads during every plan/refresh into just one read per distinct
  # bundle.
  bundle_lookup_keys = distinct([
    for k, v in var.workspaces : "${v.bundle_name}|${v.bundle_owner}"
    if v.bundle_id == null
  ])

  bundle_lookups = {
    for key in local.bundle_lookup_keys : key => {
      name  = split("|", key)[0]
      owner = split("|", key)[1]
    }
  }

  # Whether an entry actually needs a volume_encryption_key at all: AWS rejects VolumeEncryptionKey when
  # neither root nor user volume encryption is enabled, so an entry with both flags false must never be
  # assigned a key (caller-supplied or shared default).
  entry_needs_encryption_key = {
    for k, v in var.workspaces : k => v.root_volume_encryption_enabled || v.user_volume_encryption_enabled
  }

  # Whether any entry needs the shared default KMS key because it didn't supply its own volume_encryption_key
  # and actually has at least one volume encryption flag enabled (see entry_needs_encryption_key above) --
  # an entry with both flags false must not trigger creation of a key it can never use.
  default_kms_key_needed = var.enable_default_kms_key && anytrue([
    for k, v in var.workspaces : v.volume_encryption_key == null && local.entry_needs_encryption_key[k]
  ])

  # Resolve each entry's directory_id from directory_key via var.directory_id_lookup when a literal
  # directory_id was not supplied. Uses lookup() with a non-null sentinel default (rather than null or
  # direct indexing) so the resolved value stays type-correct: aws_workspaces_workspace.directory_id is a
  # required string, and a null value would fail Terraform's own required-argument check before the
  # resource's lifecycle precondition below ever runs, surfacing a generic error instead of the intended
  # clearer message. Referencing var.directory_id_lookup (a different variable from var.workspaces) inside
  # a variable validation block isn't supported on Terraform < 1.9 / OpenTofu < 1.9, so this check must live
  # here instead. See modules/aws/organizations/account/main.tf for the same pattern applied to parent_key.
  resolved_directory_ids = {
    for k, v in var.workspaces : k => v.directory_key != null ? lookup(var.directory_id_lookup, v.directory_key, "__invalid_directory_key__") : v.directory_id
  }

  resolved_bundle_ids = {
    for k, v in var.workspaces : k => coalesce(
      v.bundle_id,
      try(data.aws_workspaces_bundle.lookup["${v.bundle_name}|${v.bundle_owner}"].id, null)
    )
  }

  # Not coalesce(): coalesce() errors when every argument is null, but this should resolve to a plain null
  # (so AWS falls back to its own default key) when both volume_encryption_key and the shared default key
  # are unset, e.g. when enable_default_kms_key is false and the caller didn't supply their own key. Also
  # forced to null whenever the entry has both encryption flags disabled (entry_needs_encryption_key),
  # since AWS rejects VolumeEncryptionKey in that case even if a shared/caller key would otherwise apply.
  resolved_volume_encryption_keys = {
    for k, v in var.workspaces : k => !local.entry_needs_encryption_key[k] ? null : (
      v.volume_encryption_key != null ? v.volume_encryption_key : try(module.default_kms_key["this"].arn, null)
    )
  }
}

###########################
# Bundle Lookup
###########################

data "aws_workspaces_bundle" "lookup" {
  for_each = local.bundle_lookups

  name  = each.value.name
  owner = each.value.owner
}

###########################
# Shared Default KMS Key
###########################
# Composes modules/aws/kms (per this repository's module composition guidance) instead of an inline
# aws_kms_key, so volume encryption stays best-practice-compliant even when this module is sourced standalone.

data "aws_caller_identity" "current" {
  for_each = local.default_kms_key_needed ? { this = true } : {}
}

data "aws_iam_policy_document" "default_kms_key" {
  #checkov:skip=CKV_AWS_111:This is the standard AWS-recommended "grant full account root permissions" KMS key policy statement; Resource = "*" here is a self-reference to the key this policy is attached to, not a wildcard grant across AWS resources.
  #checkov:skip=CKV_AWS_109:Root-account access on the key's own policy is required so the key remains manageable via IAM; scoped to a single trusted account root, not broad permissions-management exposure.
  #checkov:skip=CKV_AWS_356:Resource = "*" is required and idiomatic for a KMS key policy (it always refers to the key itself), not an unconstrained wildcard on restrictable actions.
  for_each = local.default_kms_key_needed ? { this = true } : {}

  statement {
    sid       = "EnableRootAccountPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current["this"].account_id}:root"]
    }
  }

  statement {
    sid    = "AllowWorkSpacesServiceUse"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*", # Covers both GenerateDataKey and GenerateDataKeyWithoutPlaintext.
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["workspaces.amazonaws.com"]
    }
  }
}

module "default_kms_key" {
  source = "../../kms"

  for_each = local.default_kms_key_needed ? { this = true } : {}

  name_prefix = var.kms_key_alias_prefix
  description = "Shared customer-managed key used to encrypt Amazon WorkSpaces root/user volumes."
  policy      = data.aws_iam_policy_document.default_kms_key["this"].json
  tags        = merge(tomap({ Name = var.kms_key_alias_prefix }), var.tags)
}

###########################
# WorkSpaces Desktops
###########################

resource "aws_workspaces_workspace" "this" {
  for_each = var.workspaces

  directory_id                   = local.resolved_directory_ids[each.key]
  bundle_id                      = local.resolved_bundle_ids[each.key]
  user_name                      = each.value.user_name
  region                         = each.value.region
  root_volume_encryption_enabled = each.value.root_volume_encryption_enabled
  user_volume_encryption_enabled = each.value.user_volume_encryption_enabled
  volume_encryption_key          = local.resolved_volume_encryption_keys[each.key]
  tags                           = merge(tomap({ Name = each.key }), var.tags, each.value.tags)

  lifecycle {
    precondition {
      condition     = each.value.directory_key == null || contains(keys(var.directory_id_lookup), each.value.directory_key)
      error_message = "directory_key \"${coalesce(each.value.directory_key, "(none)")}\" for workspaces entry \"${each.key}\" was not found in var.directory_id_lookup. Pass the directory module's `ids` output through as directory_id_lookup."
    }
  }

  workspace_properties {
    compute_type_name    = each.value.workspace_properties.compute_type_name
    root_volume_size_gib = each.value.workspace_properties.root_volume_size_gib
    running_mode         = each.value.workspace_properties.running_mode
    # The provider never sends this timeout to AWS for ALWAYS_ON and reads it back as 0, so supplying the
    # module's AUTO_STOP-oriented default of 60 unconditionally would produce a perpetual 0 -> 60 diff for
    # ALWAYS_ON entries. Only set it for AUTO_STOP.
    running_mode_auto_stop_timeout_in_minutes = each.value.workspace_properties.running_mode == "AUTO_STOP" ? each.value.workspace_properties.running_mode_auto_stop_timeout_in_minutes : null
    user_volume_size_gib                      = each.value.workspace_properties.user_volume_size_gib
  }
}
