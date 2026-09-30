mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      node_id          = "R_mock_node"
      full_name        = "Sunward-Infrastructure/example"
      repo_id          = 42
      html_url         = "https://github.com/Sunward-Infrastructure/example"
      ssh_clone_url    = "git@github.com:Sunward-Infrastructure/example.git"
      http_clone_url   = "https://github.com/Sunward-Infrastructure/example.git"
      git_clone_url    = "git://github.com/Sunward-Infrastructure/example.git"
      svn_url          = "https://github.com/Sunward-Infrastructure/example"
      primary_language = "HCL"
    }
  }

  mock_resource "github_repository_ruleset" {
    defaults = {
      ruleset_id = 1001
    }
  }
}

variables {
  profiles = {
    aws_dev = {
      description      = "Development profile"
      homepage_url     = "https://example.com/development"
      visibility       = "private"
      topics           = ["OpenTofu", "AWS"]
      has_issues       = true
      has_projects     = false
      has_wiki         = false
      has_discussions  = false
      is_template      = false
      allow_auto_merge = true

      security_and_analysis = {
        advanced_security               = "enabled"
        secret_scanning                 = "enabled"
        secret_scanning_push_protection = "enabled"
      }
    }
    aws_test      = {}
    aws_prod      = {}
    control_plane = {}
    factory       = {}
  }

  organization_policy = {
    ruleset_name               = "change_control"
    minimum_required_approvals = 1
    verified_at                = "2026-09-14T10:00:00Z"
  }
}

run "merges_profile_and_sparse_nested_overrides" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "aws_dev"
        management_stage = "managed"
        overrides = {
          description = "Repository override"
          security_and_analysis = {
            secret_scanning = "disabled"
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository.this["example"].description == "Repository override"
    error_message = "The sparse top-level override must replace the profile description."
  }

  assert {
    condition     = github_repository.this["example"].visibility == "private"
    error_message = "Unchanged top-level settings must remain inherited from the profile."
  }

  assert {
    condition     = github_repository.this["example"].security_and_analysis[0].advanced_security[0].status == "enabled"
    error_message = "A sparse nested override must retain unrelated profile security fields."
  }

  assert {
    condition     = github_repository.this["example"].security_and_analysis[0].secret_scanning[0].status == "disabled"
    error_message = "A sparse nested override must replace the selected profile security field."
  }

}

run "normalizes_topics_deterministically" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "aws_dev"
        management_stage = "managed"
        overrides = {
          topics = [" Zeta ", "alpha", "ALPHA"]
        }
      }
    }
  }

  assert {
    condition     = github_repository.this["example"].topics == toset(["alpha", "zeta"])
    error_message = "Topics must be trimmed, lowercased, deduplicated, and sorted."
  }
}

run "excludes_inventory_repositories" {
  command = plan

  variables {
    repositories = {
      inventoried = {
        profile          = "aws_test"
        management_stage = "inventory"
      }
    }
  }

  assert {
    condition     = length(github_repository.this) == 0
    error_message = "Inventory entries must not create GitHub repository resource addresses."
  }

  assert {
    condition     = output.repository_node_ids == {}
    error_message = "Inventory entries must not appear in managed repository outputs."
  }
}

run "creates_normalized_additive_supplemental_rules" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "aws_dev"
        management_stage = "managed"
        supplemental_rules = {
          extra_status_checks = [" Zeta / check ", "alpha / check"]
          required_approvals  = 2
        }
      }
    }
  }

  assert {
    condition     = length(github_repository_ruleset.supplemental) == 1
    error_message = "A non-empty supplemental rule must create one repository ruleset."
  }

  assert {
    condition = [
      for check in github_repository_ruleset.supplemental["example"].rules[0].required_status_checks[0].required_check :
      check.context
    ] == ["Zeta / check", "alpha / check"]
    error_message = "Supplemental checks must use a deterministic trimmed order."
  }

  assert {
    condition     = github_repository_ruleset.supplemental["example"].rules[0].pull_request[0].required_approving_review_count == 2
    error_message = "The supplemental ruleset must render the stricter approval count."
  }

  assert {
    condition     = output.supplemental_ruleset_ids == { example = 1001 }
    error_message = "Supplemental ruleset IDs must be keyed by exact repository name."
  }
}

run "omits_empty_supplemental_rules" {
  command = plan

  variables {
    repositories = {
      example = {
        profile            = "aws_dev"
        management_stage   = "managed"
        supplemental_rules = {}
      }
    }
  }

  assert {
    condition     = length(github_repository_ruleset.supplemental) == 0
    error_message = "An empty supplemental rule must not duplicate organization policy."
  }
}

run "renders_pages_and_template_blocks" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "aws_dev"
        management_stage = "managed"
        overrides = {
          pages = {
            build_type = "workflow"
            cname      = "docs.example.com"
            source = {
              branch = "main"
              path   = "/docs"
            }
          }
          template = {
            owner                = "Sunward-Infrastructure"
            repository           = "repository-template"
            include_all_branches = true
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository.this["example"].pages[0].source[0].path == "/docs"
    error_message = "The Pages source block must preserve its configured path."
  }

  assert {
    condition     = github_repository.this["example"].template[0].repository == "repository-template"
    error_message = "The template block must preserve its configured source repository."
  }
}

run "wires_creation_and_legacy_repository_options" {
  command = plan

  variables {
    profiles = {
      aws_dev       = {}
      aws_test      = {}
      aws_prod      = {}
      control_plane = {}
      factory       = {}
    }
    repositories = {
      example = {
        profile          = "aws_dev"
        management_stage = "managed"
        overrides = {
          fork                                    = "true"
          source_owner                            = "upstream"
          source_repo                             = "source"
          private                                 = true
          has_downloads                           = false
          allow_forking                           = false
          auto_init                               = true
          gitignore_template                      = "Terraform"
          license_template                        = "mit"
          default_branch                          = "main"
          archive_on_destroy                      = false
          ignore_vulnerability_alerts_during_read = true
        }
      }
    }
  }

  assert {
    condition = (
      github_repository.this["example"].fork == "true" &&
      github_repository.this["example"].source_owner == "upstream" &&
      github_repository.this["example"].source_repo == "source" &&
      github_repository.this["example"].auto_init
    )
    error_message = "Creation-time repository options must pass through sparse overrides."
  }

  assert {
    condition = (
      github_repository.this["example"].has_downloads == false &&
      github_repository.this["example"].allow_forking == false &&
      github_repository.this["example"].archive_on_destroy == false
    )
    error_message = "Optional and legacy repository settings must retain explicit false values."
  }
}

run "exports_managed_repository_identifiers" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "aws_dev"
        management_stage = "managed"
      }
    }
  }

  assert {
    condition     = output.repository_node_ids == { example = "R_mock_node" }
    error_message = "Managed repository node IDs must be keyed by exact repository name."
  }

  assert {
    condition     = output.repository_full_names == { example = "Sunward-Infrastructure/example" }
    error_message = "Managed repository full names must be keyed by exact repository name."
  }

  assert {
    condition     = output.repository_ids == { example = 42 }
    error_message = "Managed numeric repository IDs must be keyed by exact repository name."
  }

  assert {
    condition     = output.repository_html_urls == { example = "https://github.com/Sunward-Infrastructure/example" }
    error_message = "Managed repository web URLs must be keyed by exact repository name."
  }

  assert {
    condition     = output.repository_ssh_clone_urls == { example = "git@github.com:Sunward-Infrastructure/example.git" }
    error_message = "Managed SSH clone URLs must be keyed by exact repository name."
  }

  assert {
    condition     = output.repository_http_clone_urls == { example = "https://github.com/Sunward-Infrastructure/example.git" }
    error_message = "Managed HTTPS clone URLs must be keyed by exact repository name."
  }

  assert {
    condition     = output.repository_git_clone_urls == { example = "git://github.com/Sunward-Infrastructure/example.git" }
    error_message = "Managed anonymous Git clone URLs must be keyed by exact repository name."
  }

  assert {
    condition     = output.repository_svn_urls == { example = "https://github.com/Sunward-Infrastructure/example" }
    error_message = "Managed Subversion URLs must be keyed by exact repository name."
  }

  assert {
    condition     = output.repository_primary_languages == { example = "HCL" }
    error_message = "Managed primary languages must be keyed by exact repository name."
  }

  assert {
    condition     = length(output.repository_pages["example"]) == 0
    error_message = "Managed Pages metadata must be keyed by exact repository name."
  }
}
