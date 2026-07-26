###########################
# Resource Variables
###########################
variable "workload_identity_providers" {
  description = <<-EOT
    Map of Scalr workload identity providers keyed by a caller-supplied logical name. Each
    entry manages one `scalr_workload_identity_provider` resource, allowing an external OIDC
    identity provider (e.g. GitHub Actions, GitLab CI) to assume a Scalr service account
    without a long-lived credential.

    Fields:
      - name:              (Required) Name of the workload identity provider.
      - url:                (Required) The URL of the workload identity provider.
      - allowed_audiences:  (Required) Set of allowed audiences. Must contain between 1 and 10
                            elements.

    Example:
      workload_identity_providers = {
        github_actions = {
          name              = "github-actions"
          url               = "https://token.actions.githubusercontent.com"
          allowed_audiences = ["scalr-github-actions"]
        }
      }
  EOT
  type = map(object({
    name              = string
    url               = string
    allowed_audiences = set(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.workload_identity_providers : length(value.allowed_audiences) >= 1 && length(value.allowed_audiences) <= 10
    ])
    error_message = "Each workload_identity_providers entry's allowed_audiences must contain between 1 and 10 elements."
  }
}
