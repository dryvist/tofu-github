# The fork approval policy gates the Default runner group's public reach.
variable "fork_pr_contributor_approval" {
  description = <<-EOT
    Approval required before fork pull-request workflows from contributors run: all_external_contributors is the strictest value; the two first_time_* values only gate contributors new to GitHub.
  EOT
  type        = string
  default     = "all_external_contributors"

  validation {
    condition     = contains(["first_time_contributors_new_to_github", "first_time_contributors", "all_external_contributors"], var.fork_pr_contributor_approval)
    error_message = "fork_pr_contributor_approval must be one of: first_time_contributors_new_to_github, first_time_contributors, all_external_contributors."
  }
}

variable "default_runner_group_allows_public_repositories" {
  description = <<-EOT
    Whether the built-in Default runner group may serve public repositories; keep true only with the strictest fork approval policy.
  EOT
  type        = bool
  default     = true

  validation {
    condition     = !var.default_runner_group_allows_public_repositories || var.fork_pr_contributor_approval == "all_external_contributors"
    error_message = "default_runner_group_allows_public_repositories requires fork_pr_contributor_approval to be all_external_contributors."
  }
}
