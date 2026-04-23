###########################
# Hook Variables
###########################
variable "hooks" {
  description = "Map of hooks to register in the Scalr hooks registry. The map key is used as a unique identifier and as the hook name if 'name' is not specified within the hook definition."
  type = map(object({
    description     = optional(string)
    interpreter     = optional(string)
    name            = optional(string)
    scriptfile_path = string
    vcs_provider_id = optional(string)
    vcs_repo = optional(object({
      identifier = string
      branch     = optional(string)
    }))
  }))
  default = {}
}

###########################
# General Variables
###########################
variable "interpreter" {
  description = "The default interpreter used to execute hook scripts. Can be overridden per hook in the hooks map. Common values are 'bash' and 'python3'."
  type        = string
  default     = "bash"
}

variable "vcs_provider_id" {
  description = "The default VCS provider ID in the format 'vcs-<RANDOM STRING>'. Can be overridden per hook in the hooks map."
  type        = string
  default     = null
}

variable "vcs_repo_identifier" {
  description = "The default VCS repository identifier in the format 'org/repo'. Used when vcs_repo is not specified per hook. Can be overridden per hook in the hooks map."
  type        = string
  default     = null
}

variable "vcs_repo_branch" {
  description = "The default VCS repository branch to pull hook scripts from. Can be overridden per hook in the hooks map."
  type        = string
  default     = "main"
}
