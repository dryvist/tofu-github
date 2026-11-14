# Inputs for actions-policy.tf, which declares the fork approval policy and
# the Default runner group's reach.

# The fork approval policy gates the Default runner group's public reach.
variable "fork_pr_contributor_approval" {
  description = "Approval before fork PR workflows run; first_time_* gate only contributors new to GitHub."
  type        = string
  default     = "all_external_contributors"
  validation {
    condition     = contains(["first_time_contributors_new_to_github", "first_time_contributors", "all_external_contributors"], var.fork_pr_contributor_approval)
    error_message = "Use first_time_contributors_new_to_github, first_time_contributors or all_external_contributors."
  }
}

variable "default_runner_group_allows_public_repositories" {
  description = "Default runner group serves public repos; requires the all_external_contributors fork approval policy."
  type        = bool
  default     = true
  validation {
    condition     = !var.default_runner_group_allows_public_repositories || var.fork_pr_contributor_approval == "all_external_contributors"
    error_message = "Requires all_external_contributors fork approval."
  }
}
