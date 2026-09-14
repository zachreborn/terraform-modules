###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.11.0"
    }
  }

}

###########################
# Repository Configuration
###########################
locals {
  resolved_repositories = {
    for name, repository in var.repositories : name => {
      management_stage = repository.management_stage

      description  = try(repository.overrides.description != null ? repository.overrides.description : var.profiles[repository.profile].description, null)
      homepage_url = try(repository.overrides.homepage_url != null ? repository.overrides.homepage_url : var.profiles[repository.profile].homepage_url, null)
      fork         = try(coalesce(repository.overrides.fork, var.profiles[repository.profile].fork), null)
      source_owner = try(coalesce(repository.overrides.source_owner, var.profiles[repository.profile].source_owner), null)
      source_repo  = try(coalesce(repository.overrides.source_repo, var.profiles[repository.profile].source_repo), null)
      private      = try(coalesce(repository.overrides.private, var.profiles[repository.profile].private), null)
      visibility   = try(coalesce(repository.overrides.visibility, var.profiles[repository.profile].visibility), null)
      topics = try(sort(distinct([
        for topic in(repository.overrides.topics != null ? repository.overrides.topics : var.profiles[repository.profile].topics) :
        lower(trimspace(topic))
      ])), null)
      has_issues   = try(coalesce(repository.overrides.has_issues, var.profiles[repository.profile].has_issues), null)
      has_projects = try(coalesce(repository.overrides.has_projects, var.profiles[repository.profile].has_projects), null)
      has_wiki     = try(coalesce(repository.overrides.has_wiki, var.profiles[repository.profile].has_wiki), null)
      has_downloads = try(coalesce(
        repository.overrides.has_downloads,
        var.profiles[repository.profile].has_downloads
      ), null)
      has_discussions = try(coalesce(
        repository.overrides.has_discussions,
        var.profiles[repository.profile].has_discussions
      ), null)
      is_template        = try(coalesce(repository.overrides.is_template, var.profiles[repository.profile].is_template), null)
      allow_merge_commit = try(coalesce(repository.overrides.allow_merge_commit, var.profiles[repository.profile].allow_merge_commit), null)
      allow_squash_merge = try(coalesce(repository.overrides.allow_squash_merge, var.profiles[repository.profile].allow_squash_merge), null)
      allow_rebase_merge = try(coalesce(repository.overrides.allow_rebase_merge, var.profiles[repository.profile].allow_rebase_merge), null)
      allow_auto_merge   = try(coalesce(repository.overrides.allow_auto_merge, var.profiles[repository.profile].allow_auto_merge), null)
      allow_forking      = try(coalesce(repository.overrides.allow_forking, var.profiles[repository.profile].allow_forking), null)
      allow_update_branch = try(coalesce(
        repository.overrides.allow_update_branch,
        var.profiles[repository.profile].allow_update_branch
      ), null)
      delete_branch_on_merge = try(coalesce(
        repository.overrides.delete_branch_on_merge,
        var.profiles[repository.profile].delete_branch_on_merge
      ), null)
      web_commit_signoff_required = try(coalesce(
        repository.overrides.web_commit_signoff_required,
        var.profiles[repository.profile].web_commit_signoff_required
      ), null)
      squash_merge_commit_title = try(coalesce(
        repository.overrides.squash_merge_commit_title,
        var.profiles[repository.profile].squash_merge_commit_title
      ), null)
      squash_merge_commit_message = try(coalesce(
        repository.overrides.squash_merge_commit_message,
        var.profiles[repository.profile].squash_merge_commit_message
      ), null)
      merge_commit_title = try(coalesce(
        repository.overrides.merge_commit_title,
        var.profiles[repository.profile].merge_commit_title
      ), null)
      merge_commit_message = try(coalesce(
        repository.overrides.merge_commit_message,
        var.profiles[repository.profile].merge_commit_message
      ), null)
      vulnerability_alerts = try(coalesce(
        repository.overrides.vulnerability_alerts,
        var.profiles[repository.profile].vulnerability_alerts
      ), null)
      ignore_vulnerability_alerts_during_read = try(coalesce(
        repository.overrides.ignore_vulnerability_alerts_during_read,
        var.profiles[repository.profile].ignore_vulnerability_alerts_during_read
      ), null)
      auto_init          = try(coalesce(repository.overrides.auto_init, var.profiles[repository.profile].auto_init), null)
      gitignore_template = try(coalesce(repository.overrides.gitignore_template, var.profiles[repository.profile].gitignore_template), null)
      license_template   = try(coalesce(repository.overrides.license_template, var.profiles[repository.profile].license_template), null)
      default_branch     = try(coalesce(repository.overrides.default_branch, var.profiles[repository.profile].default_branch), null)
      archived           = try(coalesce(repository.overrides.archived, var.profiles[repository.profile].archived), null)
      archive_on_destroy = try(coalesce(repository.overrides.archive_on_destroy, var.profiles[repository.profile].archive_on_destroy), null)

      pages = {
        build_type = try(coalesce(
          try(repository.overrides.pages.build_type, null),
          try(var.profiles[repository.profile].pages.build_type, null)
        ), null)
        cname = try(
          try(repository.overrides.pages.cname, null) != null ?
          repository.overrides.pages.cname :
          var.profiles[repository.profile].pages.cname,
          null
        )
        source = {
          branch = try(coalesce(
            try(repository.overrides.pages.source.branch, null),
            try(var.profiles[repository.profile].pages.source.branch, null)
          ), null)
          path = try(coalesce(
            try(repository.overrides.pages.source.path, null),
            try(var.profiles[repository.profile].pages.source.path, null)
          ), null)
        }
      }

      template = {
        owner = try(coalesce(
          try(repository.overrides.template.owner, null),
          try(var.profiles[repository.profile].template.owner, null)
        ), null)
        repository = try(coalesce(
          try(repository.overrides.template.repository, null),
          try(var.profiles[repository.profile].template.repository, null)
        ), null)
        include_all_branches = try(coalesce(
          try(repository.overrides.template.include_all_branches, null),
          try(var.profiles[repository.profile].template.include_all_branches, null)
        ), null)
      }

      security_and_analysis = {
        advanced_security = try(coalesce(
          try(repository.overrides.security_and_analysis.advanced_security, null),
          try(var.profiles[repository.profile].security_and_analysis.advanced_security, null)
        ), null)
        code_security = try(coalesce(
          try(repository.overrides.security_and_analysis.code_security, null),
          try(var.profiles[repository.profile].security_and_analysis.code_security, null)
        ), null)
        secret_scanning = try(coalesce(
          try(repository.overrides.security_and_analysis.secret_scanning, null),
          try(var.profiles[repository.profile].security_and_analysis.secret_scanning, null)
        ), null)
        secret_scanning_push_protection = try(coalesce(
          try(repository.overrides.security_and_analysis.secret_scanning_push_protection, null),
          try(var.profiles[repository.profile].security_and_analysis.secret_scanning_push_protection, null)
        ), null)
        secret_scanning_ai_detection = try(coalesce(
          try(repository.overrides.security_and_analysis.secret_scanning_ai_detection, null),
          try(var.profiles[repository.profile].security_and_analysis.secret_scanning_ai_detection, null)
        ), null)
        secret_scanning_non_provider_patterns = try(coalesce(
          try(repository.overrides.security_and_analysis.secret_scanning_non_provider_patterns, null),
          try(var.profiles[repository.profile].security_and_analysis.secret_scanning_non_provider_patterns, null)
        ), null)
      }

      supplemental_rules = repository.supplemental_rules == null ? null : {
        extra_status_checks = sort(distinct([
          for check in repository.supplemental_rules.extra_status_checks : trimspace(check)
        ]))
        required_approvals = repository.supplemental_rules.required_approvals
      }
    }
  }

  managed_repositories = {
    for name, repository in local.resolved_repositories : name => repository
    if repository.management_stage == "managed"
  }

  supplemental_rulesets = {
    for name, repository in local.managed_repositories : name => repository.supplemental_rules
    if repository.supplemental_rules != null && (
      length(repository.supplemental_rules.extra_status_checks) > 0 ||
      repository.supplemental_rules.required_approvals != null
    )
  }
}

###########################
# GitHub Repositories
###########################
resource "github_repository" "this" {
  #checkov:skip=CKV_GIT_1: Visibility is a validated caller setting because this reusable module manages public, private, and internal repositories.
  for_each = local.managed_repositories

  name                                    = each.key
  description                             = each.value.description
  homepage_url                            = each.value.homepage_url
  fork                                    = each.value.fork
  source_owner                            = each.value.source_owner
  source_repo                             = each.value.source_repo
  private                                 = each.value.private
  visibility                              = each.value.visibility
  topics                                  = each.value.topics
  has_issues                              = each.value.has_issues
  has_projects                            = each.value.has_projects
  has_wiki                                = each.value.has_wiki
  has_discussions                         = each.value.has_discussions
  has_downloads                           = each.value.has_downloads
  is_template                             = each.value.is_template
  allow_merge_commit                      = each.value.allow_merge_commit
  allow_squash_merge                      = each.value.allow_squash_merge
  allow_rebase_merge                      = each.value.allow_rebase_merge
  allow_auto_merge                        = each.value.allow_auto_merge
  allow_forking                           = each.value.allow_forking
  allow_update_branch                     = each.value.allow_update_branch
  delete_branch_on_merge                  = each.value.delete_branch_on_merge
  web_commit_signoff_required             = each.value.web_commit_signoff_required
  squash_merge_commit_title               = each.value.squash_merge_commit_title
  squash_merge_commit_message             = each.value.squash_merge_commit_message
  merge_commit_title                      = each.value.merge_commit_title
  merge_commit_message                    = each.value.merge_commit_message
  vulnerability_alerts                    = each.value.vulnerability_alerts
  ignore_vulnerability_alerts_during_read = each.value.ignore_vulnerability_alerts_during_read
  auto_init                               = each.value.auto_init
  gitignore_template                      = each.value.gitignore_template
  license_template                        = each.value.license_template
  default_branch                          = each.value.default_branch
  archived                                = each.value.archived
  archive_on_destroy                      = each.value.archive_on_destroy

  dynamic "pages" {
    for_each = anytrue(concat(
      [each.value.pages.build_type != null, each.value.pages.cname != null],
      [for value in values(each.value.pages.source) : value != null]
    )) ? [each.value.pages] : []

    content {
      build_type = pages.value.build_type
      cname      = pages.value.cname

      dynamic "source" {
        for_each = pages.value.source.branch == null ? [] : [pages.value.source]
        content {
          branch = source.value.branch
          path   = source.value.path
        }
      }
    }
  }

  dynamic "security_and_analysis" {
    for_each = anytrue([
      for status in values(each.value.security_and_analysis) : status != null
    ]) ? [each.value.security_and_analysis] : []

    content {
      dynamic "advanced_security" {
        for_each = security_and_analysis.value.advanced_security == null ? [] : [security_and_analysis.value.advanced_security]
        content {
          status = advanced_security.value
        }
      }

      dynamic "code_security" {
        for_each = security_and_analysis.value.code_security == null ? [] : [security_and_analysis.value.code_security]
        content {
          status = code_security.value
        }
      }

      dynamic "secret_scanning" {
        for_each = security_and_analysis.value.secret_scanning == null ? [] : [security_and_analysis.value.secret_scanning]
        content {
          status = secret_scanning.value
        }
      }

      dynamic "secret_scanning_push_protection" {
        for_each = security_and_analysis.value.secret_scanning_push_protection == null ? [] : [security_and_analysis.value.secret_scanning_push_protection]
        content {
          status = secret_scanning_push_protection.value
        }
      }

      dynamic "secret_scanning_ai_detection" {
        for_each = security_and_analysis.value.secret_scanning_ai_detection == null ? [] : [security_and_analysis.value.secret_scanning_ai_detection]
        content {
          status = secret_scanning_ai_detection.value
        }
      }

      dynamic "secret_scanning_non_provider_patterns" {
        for_each = security_and_analysis.value.secret_scanning_non_provider_patterns == null ? [] : [security_and_analysis.value.secret_scanning_non_provider_patterns]
        content {
          status = secret_scanning_non_provider_patterns.value
        }
      }
    }
  }

  dynamic "template" {
    for_each = each.value.template.owner == null || each.value.template.repository == null ? [] : [each.value.template]

    content {
      owner                = template.value.owner
      repository           = template.value.repository
      include_all_branches = template.value.include_all_branches
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

###########################
# Supplemental Rulesets
###########################
resource "github_repository_ruleset" "supplemental" {
  for_each = local.supplemental_rulesets

  name        = "supplemental_change_control"
  repository  = github_repository.this[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    dynamic "required_status_checks" {
      for_each = length(each.value.extra_status_checks) == 0 ? [] : [each.value.extra_status_checks]

      content {
        strict_required_status_checks_policy = true

        dynamic "required_check" {
          for_each = required_status_checks.value
          content {
            context = required_check.value
          }
        }
      }
    }

    dynamic "pull_request" {
      for_each = each.value.required_approvals == null ? [] : [each.value.required_approvals]

      content {
        required_approving_review_count = pull_request.value
      }
    }
  }
}
