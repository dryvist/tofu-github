variable "name" {
  description = "Repo name without owner. The owner is supplied by the calling module's GitHub provider, so it never appears here."
  type        = string
}

variable "description" {
  description = "Repo description (1-line, shown on GitHub)."
  type        = string
}

variable "topics" {
  description = "GitHub topic tags."
  type        = list(string)
  default     = []
}

variable "visibility" {
  description = <<-EOT
    Repo visibility: "public" or "private". Drives the secret-scanning cost
    gate. Secret scanning and push protection require GitHub Advanced Security
    on private repos (paid: Secret Protection) but are free on public repos, so
    the module only sets the security_and_analysis block when this is "public".
    A private repo therefore never has a paid feature enabled by an apply.
  EOT
  type        = string

  validation {
    condition     = contains(["public", "private"], var.visibility)
    error_message = "visibility must be one of: public, private."
  }
}

variable "archived" {
  description = <<-EOT
    Archive the repository. Defaults to false. The GitHub API does not
    support unarchiving, so this is one-way: only set true for a repo that is
    permanently frozen (superseded, consolidated elsewhere, etc.) — record
    the reason in an ADR or the repo's own README, and reference it in
    config/repos.yml. Archiving itself is applied here so a later plan
    doesn't show drift once the repo is archived out-of-band, but most other
    settings on an already-archived repo are read-only via the GitHub API;
    don't add new managed attributes to an archived entry expecting them to
    apply.
  EOT
  type        = bool
  default     = false
}
