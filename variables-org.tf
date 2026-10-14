# Workspace selection: which organization, token permission set and config directory this workspace manages.
variable "github_owner" {
  description = "GitHub organization login managed by this workspace."
  type        = string
  default     = "dryvist"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,39}$", var.github_owner))
    error_message = "github_owner must contain 1-39 letters, numbers, or hyphens."
  }
}

variable "github_token_permission_set" {
  description = "OpenBao permission-set name used to mint this workspace's GitHub installation token."
  type        = string
  default     = "dryvist-full-automation"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", var.github_token_permission_set))
    error_message = "github_token_permission_set must be a single path component containing letters, numbers, underscores, or hyphens."
  }
}

variable "config_org" {
  description = "Per-org config directory under config/orgs/. Empty uses the existing files directly in config/."
  type        = string
  default     = ""

  validation {
    condition     = var.config_org == "" || can(regex("^[A-Za-z0-9_-]+$", var.config_org))
    error_message = "config_org must be empty or contain only letters, numbers, underscores, and hyphens."
  }
}

variable "private_repo_overrides" {
  description = "Per-repo overrides for private repositories, keyed by repo name, in the same shape as the repos map in repos.yml. Supplied as a workspace variable so private repo names stay out of this public repository."
  type        = any
  default     = {}
}
