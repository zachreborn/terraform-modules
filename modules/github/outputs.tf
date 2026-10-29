###########################
# Repository Outputs
###########################
output "repository_node_ids" {
  description = "Map of GitHub GraphQL node IDs for managed repositories, keyed by exact repository name."
  value       = { for name, repository in github_repository.this : name => repository.node_id }
}

output "repository_full_names" {
  description = "Map of owner/repository names for managed repositories, keyed by exact repository name."
  value       = { for name, repository in github_repository.this : name => repository.full_name }
}

output "repository_ids" {
  description = "Map of GitHub numeric repository IDs for managed repositories, keyed by exact repository name."
  value       = { for name, repository in github_repository.this : name => repository.repo_id }
}

output "repository_html_urls" {
  description = "Map of GitHub web URLs for managed repositories, keyed by exact repository name."
  value       = { for name, repository in github_repository.this : name => repository.html_url }
}

output "repository_ssh_clone_urls" {
  description = "Map of SSH clone URLs for managed repositories, keyed by exact repository name."
  value       = { for name, repository in github_repository.this : name => repository.ssh_clone_url }
}

output "repository_http_clone_urls" {
  description = "Map of HTTPS clone URLs for managed repositories, keyed by exact repository name."
  value       = { for name, repository in github_repository.this : name => repository.http_clone_url }
}

output "repository_git_clone_urls" {
  description = "Map of anonymous Git clone URLs for managed repositories, keyed by exact repository name."
  value       = { for name, repository in github_repository.this : name => repository.git_clone_url }
}

output "repository_svn_urls" {
  description = "Map of Subversion URLs for managed repositories, keyed by exact repository name."
  value       = { for name, repository in github_repository.this : name => repository.svn_url }
}

output "repository_primary_languages" {
  description = "Map of primary languages for managed repositories, keyed by exact repository name."
  value       = { for name, repository in github_repository.this : name => repository.primary_language }
}

output "repository_pages" {
  description = "Map of computed GitHub Pages metadata for managed repositories, keyed by exact repository name."
  value       = { for name, repository in github_repository.this : name => repository.pages }
}

output "supplemental_ruleset_ids" {
  description = "Map of GitHub ruleset IDs for repositories with supplemental rules, keyed by exact repository name."
  value       = { for name, ruleset in github_repository_ruleset.supplemental : name => ruleset.ruleset_id }
}
