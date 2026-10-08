###########################
# Repository Profiles
###########################
variable "profiles" {
  description = <<-EOT
    Repository setting profiles keyed by profile name. The map must contain aws_dev, aws_test,
    aws_prod, control_plane, and factory. Every setting is optional so an import-first caller can
    represent the current GitHub value without forcing unrelated standardization.
  EOT

  type = map(object({
    description                             = optional(string)
    homepage_url                            = optional(string)
    fork                                    = optional(string)
    source_owner                            = optional(string)
    source_repo                             = optional(string)
    private                                 = optional(bool)
    visibility                              = optional(string)
    topics                                  = optional(set(string))
    has_issues                              = optional(bool)
    has_projects                            = optional(bool)
    has_wiki                                = optional(bool)
    has_downloads                           = optional(bool)
    has_discussions                         = optional(bool)
    is_template                             = optional(bool)
    allow_merge_commit                      = optional(bool)
    allow_squash_merge                      = optional(bool)
    allow_rebase_merge                      = optional(bool)
    allow_auto_merge                        = optional(bool)
    allow_forking                           = optional(bool)
    allow_update_branch                     = optional(bool)
    delete_branch_on_merge                  = optional(bool)
    web_commit_signoff_required             = optional(bool)
    squash_merge_commit_title               = optional(string)
    squash_merge_commit_message             = optional(string)
    merge_commit_title                      = optional(string)
    merge_commit_message                    = optional(string)
    vulnerability_alerts                    = optional(bool)
    ignore_vulnerability_alerts_during_read = optional(bool)
    auto_init                               = optional(bool)
    gitignore_template                      = optional(string)
    license_template                        = optional(string)
    default_branch                          = optional(string)
    archived                                = optional(bool)
    archive_on_destroy                      = optional(bool)

    pages = optional(object({
      build_type = optional(string)
      cname      = optional(string)
      source = optional(object({
        branch = string
        path   = optional(string)
      }))
    }))

    security_and_analysis = optional(object({
      advanced_security               = optional(string)
      secret_scanning                 = optional(string)
      secret_scanning_push_protection = optional(string)
    }))

    template = optional(object({
      owner                = string
      repository           = string
      include_all_branches = optional(bool)
    }))
  }))

  validation {
    condition = alltrue([
      for profile in values(var.profiles) :
      profile.fork == null || contains(["true", "false"], profile.fork)
    ])
    error_message = "Each profile fork must be null, \"true\", or \"false\"."
  }


  validation {
    condition = length(setsubtract(
      toset(["aws_dev", "aws_test", "aws_prod", "control_plane", "factory"]),
      toset(keys(var.profiles))
    )) == 0
    error_message = "profiles must contain aws_dev, aws_test, aws_prod, control_plane, and factory."
  }

  validation {
    condition = alltrue([
      for profile in values(var.profiles) :
      profile.visibility == null || contains(["public", "private", "internal"], profile.visibility)
    ])
    error_message = "Each profile visibility must be null, \"public\", \"private\", or \"internal\"."
  }

  validation {
    condition = alltrue(flatten([
      for profile in values(var.profiles) : [
        for topic in coalesce(profile.topics, []) : trimspace(topic) != ""
      ]
    ]))
    error_message = "Profile topics must not be empty or whitespace-only."
  }

  validation {
    condition = alltrue(flatten([
      for profile in values(var.profiles) : [
        for status in profile.security_and_analysis == null ? [] : values(profile.security_and_analysis) :
        status == null || contains(["enabled", "disabled"], status)
      ]
    ]))
    error_message = "Each profile security_and_analysis status must be null, \"enabled\", or \"disabled\"."
  }

}

###########################
# Repository Inventory
###########################
variable "repositories" {
  description = <<-EOT
    Repository inventory keyed by exact GitHub repository name.
      - profile: One key from profiles.
      - management_stage: inventory records reviewable data; managed creates a resource address.
      - overrides: Sparse repository settings. Nested security settings merge field by field.
      - supplemental_rules: Optional additive checks or an approval count that cannot be lower than
        organization_policy.minimum_required_approvals.
      - supplemental_rules.bypass_actors: Reserved rejection guard. It must remain empty because this
        module never renders bypass actors.
  EOT

  type = map(object({
    profile          = string
    management_stage = string

    overrides = optional(object({
      description                             = optional(string)
      homepage_url                            = optional(string)
      fork                                    = optional(string)
      source_owner                            = optional(string)
      source_repo                             = optional(string)
      private                                 = optional(bool)
      visibility                              = optional(string)
      topics                                  = optional(set(string))
      has_issues                              = optional(bool)
      has_projects                            = optional(bool)
      has_wiki                                = optional(bool)
      has_downloads                           = optional(bool)
      has_discussions                         = optional(bool)
      is_template                             = optional(bool)
      allow_merge_commit                      = optional(bool)
      allow_squash_merge                      = optional(bool)
      allow_rebase_merge                      = optional(bool)
      allow_auto_merge                        = optional(bool)
      allow_forking                           = optional(bool)
      allow_update_branch                     = optional(bool)
      delete_branch_on_merge                  = optional(bool)
      web_commit_signoff_required             = optional(bool)
      squash_merge_commit_title               = optional(string)
      squash_merge_commit_message             = optional(string)
      merge_commit_title                      = optional(string)
      merge_commit_message                    = optional(string)
      vulnerability_alerts                    = optional(bool)
      ignore_vulnerability_alerts_during_read = optional(bool)
      auto_init                               = optional(bool)
      gitignore_template                      = optional(string)
      license_template                        = optional(string)
      default_branch                          = optional(string)
      archived                                = optional(bool)
      archive_on_destroy                      = optional(bool)

      pages = optional(object({
        build_type = optional(string)
        cname      = optional(string)
        source = optional(object({
          branch = optional(string)
          path   = optional(string)
        }))
      }))

      security_and_analysis = optional(object({
        advanced_security               = optional(string)
        secret_scanning                 = optional(string)
        secret_scanning_push_protection = optional(string)
      }))

      template = optional(object({
        owner                = optional(string)
        repository           = optional(string)
        include_all_branches = optional(bool)
      }))
    }), {})

    supplemental_rules = optional(object({
      extra_status_checks = optional(set(string), [])
      required_approvals  = optional(number)
      bypass_actors = optional(set(object({
        actor_id   = number
        actor_type = string
      })), [])
    }))
  }))

  default = {}
  validation {
    condition = alltrue([
      for repository in values(var.repositories) :
      repository.overrides.fork == null ||
      contains(["true", "false"], repository.overrides.fork)
    ])
    error_message = "Each repository override fork must be null, \"true\", or \"false\"."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) : contains(keys(var.profiles), repository.profile)
    ])
    error_message = "Each repository profile must name an existing profiles key."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) :
      contains(["inventory", "managed"], repository.management_stage)
    ])
    error_message = "Each repository management_stage must be \"inventory\" or \"managed\"."
  }

  validation {
    condition = alltrue([
      for name in keys(var.repositories) :
      length(name) <= 100 && can(regex("^[A-Za-z0-9._-]+$", name))
    ])
    error_message = "Each repository name must be 1-100 characters and contain only letters, numbers, periods, underscores, or hyphens."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) :
      repository.overrides.visibility == null ||
      contains(["public", "private", "internal"], repository.overrides.visibility)
    ])
    error_message = "Each repository override visibility must be null, \"public\", \"private\", or \"internal\"."
  }

  validation {
    condition = alltrue(flatten([
      for repository in values(var.repositories) : [
        for topic in coalesce(repository.overrides.topics, []) : trimspace(topic) != ""
      ]
    ]))
    error_message = "Repository override topics must not be empty or whitespace-only."
  }

  validation {
    condition = alltrue(flatten([
      for repository in values(var.repositories) : [
        for status in repository.overrides.security_and_analysis == null ? [] : values(repository.overrides.security_and_analysis) :
        status == null || contains(["enabled", "disabled"], status)
      ]
    ]))
    error_message = "Each repository override security_and_analysis status must be null, \"enabled\", or \"disabled\"."
  }


  validation {
    condition = alltrue(flatten([
      for repository in values(var.repositories) : [
        for check in repository.supplemental_rules == null ? [] : repository.supplemental_rules.extra_status_checks :
        trimspace(check) != ""
      ]
    ]))
    error_message = "Supplemental status-check names must not be empty or whitespace-only."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) :
      repository.supplemental_rules == null ||
      repository.supplemental_rules.required_approvals == null ||
      (
        repository.supplemental_rules.required_approvals >= var.organization_policy.minimum_required_approvals &&
        repository.supplemental_rules.required_approvals <= 10 &&
        repository.supplemental_rules.required_approvals == floor(repository.supplemental_rules.required_approvals)
      )
    ])
    error_message = "Supplemental required_approvals must be a whole number from organization_policy.minimum_required_approvals through 10."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) :
      repository.supplemental_rules == null ||
      length(repository.supplemental_rules.bypass_actors) == 0
    ])
    error_message = "Supplemental bypass actors are not supported; change_control remains authoritative."
  }
}

###########################
# Organization Policy Guard
###########################
variable "organization_policy" {
  description = "Reviewed snapshot guard for the authoritative organization change_control ruleset."

  type = object({
    ruleset_name               = string
    minimum_required_approvals = number
    verified_at                = string
  })

  validation {
    condition     = var.organization_policy.ruleset_name == "change_control"
    error_message = "organization_policy.ruleset_name must equal \"change_control\"."
  }

  validation {
    condition = (
      var.organization_policy.minimum_required_approvals >= 0 &&
      var.organization_policy.minimum_required_approvals <= 10 &&
      var.organization_policy.minimum_required_approvals == floor(var.organization_policy.minimum_required_approvals)
    )
    error_message = "organization_policy.minimum_required_approvals must be a whole number from 0 through 10."
  }

  validation {
    condition     = can(formatdate("YYYY-MM-DD'T'hh:mm:ssZ", var.organization_policy.verified_at))
    error_message = "organization_policy.verified_at must be a valid RFC 3339 timestamp."
  }
}
