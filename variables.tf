# Enforcement inputs: disabled, evaluate, or active.
variable "markdown_lint_enforcement" {
  description = "Org markdown-lint enforcement: evaluate in Insights; activate when the fleet is green."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.markdown_lint_enforcement)
    error_message = "markdown_lint_enforcement: disabled, evaluate, or active."
  }
}

variable "conventions_enforcement" {
  description = "Org repo-conventions checks (LICENSE, AGENTS.md, Nix dev shell, release-please): evaluate; CONVENTIONS_STRICT opts repos into failure; activate when green."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.conventions_enforcement)
    error_message = "conventions_enforcement: disabled, evaluate, or active."
  }
}

variable "ai_review_enforcement" {
  description = "Org-wide AI review injects .github/ai-review.yml into every repo's PRs via PR-Agent on the model router: evaluate; active waits out router outages, then blocks merges."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.ai_review_enforcement)
    error_message = "ai_review_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "docs_publisher_enforcement" {
  description = <<-EOT
    Documentation publisher requires its configured approval count; release and triage apps bypass PRs.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.docs_publisher_enforcement)
    error_message = "docs_publisher_enforcement: disabled, evaluate, or active."
  }
}

variable "org_branch_protection_enforcement" {
  description = "Default-branch rules require signatures, branch-name pattern, Conventional Commits, thread resolution; no bypass, even for admins."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_branch_protection_enforcement)
    error_message = "org_branch_protection_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "required_signatures_enforcement" {
  description = "Org-wide required-signatures rule for all branches."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.required_signatures_enforcement)
    error_message = "required_signatures_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_review_gate_enforcement" {
  description = "Default-branch gate requires one approval and CODEOWNER review; OrganizationAdmin and release automation bypass."
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_review_gate_enforcement)
    error_message = "org_review_gate_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_gitflow_base_enforcement" {
  description = <<-EOT
    Git-flow base applies only to local.gitflow_repos: signatures on main and develop.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_gitflow_base_enforcement)
    error_message = "Enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_gitflow_main_enforcement" {
  description = "Git-flow main, only local.gitflow_repos: PRs, merge commits only, thread resolution, Conventional-Commits-or-merge messages; signatures from org-gitflow-base and org-wide rulesets."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_gitflow_main_enforcement)
    error_message = "org_gitflow_main_enforcement: disabled, evaluate, or active."
  }
}

variable "org_gitflow_develop_enforcement" {
  description = "Git-flow develop, only local.gitflow_repos: PRs, merge methods from config/rulesets-defaults.yml; its only rule is the Conventional-Commits-or-merge pattern, so main back-merges pass. Signatures from org-gitflow-base and org-wide rulesets."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_gitflow_develop_enforcement)
    error_message = "org_gitflow_develop_enforcement: disabled, evaluate, or active."
  }
}

variable "org_release_freeze_enforcement" {
  description = "Git-flow repos require the release-freeze status check on develop; evaluate until every git-flow repo calls the shared status workflow."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_release_freeze_enforcement)
    error_message = "org_release_freeze_enforcement: disabled, evaluate, or active."
  }
}

variable "org_copilot_review_enforcement" {
  description = "Pilot targets explicit branches and repos in selected copilot-review.yml; expand it there. Paid: AI credits per review, no seats; review_on_push=false caps ~one review per PR."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_copilot_review_enforcement)
    error_message = "org_copilot_review_enforcement: disabled, evaluate, or active."
  }
}

variable "org_push_protection_enforcement" {
  description = "Native max_file_size and file_extension_restriction rules cover every repo/ref at the git layer."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_push_protection_enforcement)
    error_message = "org_push_protection_enforcement: disabled, evaluate, or active."
  }
}

variable "org_code_scanning_enforcement" {
  description = "Require CodeQL default-setup results on public repos' default branch and main before updates; evaluate until every target has a configured CodeQL analysis."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_code_scanning_enforcement)
    error_message = "org_code_scanning_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "codeql_import_enabled" {
  description = "Adopt the existing CodeQL default-setup config through the import block in code_scanning.tf."
  type        = bool
  default     = true
}

variable "org_merge_gate_enforcement" {
  description = "org-merge-gate-* checks block merges to main; each repo needs a live gate context on main before activation."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_merge_gate_enforcement)
    error_message = "org_merge_gate_enforcement: disabled, evaluate, or active."
  }
}

variable "merge_gate_strict_enforcement" {
  description = "org-merge-gate-strict-* checks require PRs up to date with their base before merging, except the automation apps in merge-gate-strict.tf; evaluate."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.merge_gate_strict_enforcement)
    error_message = "merge_gate_strict_enforcement: disabled, evaluate, or active."
  }
}

variable "org_upstream_fork_protection_enforcement" {
  description = "For upstream_fork=true, default branch requires PRs and merge commits; deletion and force-push forbidden."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_upstream_fork_protection_enforcement)
    error_message = "org_upstream_fork_protection_enforcement: disabled, evaluate, or active."
  }
}

variable "org_branch_write_restriction_enforcement" {
  description = <<-EOT
    Org-wide active branch-write restriction blocks actors outside var.automation_bypass_app_ids from writing branches except main.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_branch_write_restriction_enforcement)
    error_message = "org_branch_write_restriction_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "automation_bypass_app_ids" {
  description = "Required, no default: GitHub App IDs allowed to write branches covered by the branch-write restriction; include every branch-writer (Actions, dependency-update, release, org apps)."
  type        = list(number)

  validation {
    condition     = length(var.automation_bypass_app_ids) > 0
    error_message = "automation_bypass_app_ids must list at least one GitHub App ID."
  }
}

# Workspace selectors.
variable "github_owner" {
  description = "GitHub org login to manage: 1-39 letters, digits, or hyphens."
  type        = string
  default     = "dryvist"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,39}$", var.github_owner))
    error_message = "github_owner must contain 1-39 letters, numbers, or hyphens."
  }
}

variable "dryvist_org_extras" {
  description = "Enable organization-specific opt-in policies."
  type        = bool
  default     = true
}

variable "org_automerge_manual_enforcement" {
  description = "Enforces automerge=manual review: one approval on main/develop; OrganizationAdmin, agent, triage, and release apps bypass."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled","evaluate","active"], var.org_automerge_manual_enforcement)
    error_message = "org_automerge_manual_enforcement: disabled, evaluate, or active."
  }
}

# Hermes PR-review webhook sends pull_request events; created only when both
# variables are set.
variable "hermes_webhook_url" {
  description = "Hermes PR-review intake URL; empty skips the webhook."
  type        = string
  sensitive   = true
  default     = ""
}

variable "hermes_webhook_secret" {
  description = "GitHub HMAC signing secret (X-Hub-Signature-256); empty skips the webhook."
  type        = string
  sensitive   = true
  default     = ""
}

# Event queue intake for check_run and pull_request events. Off until the intake
# records exist in Vault, so the plan never reads absent paths.
variable "event_queue_webhook_enabled" {
  description = "Create the event queue org webhook from the intake records in Vault."
  type        = bool
  default     = false
}

variable "event_forwarder_enabled" {
  description = "Enable the org-wide event-forwarder required workflow."
  type        = bool
  default     = false
}

variable "event_forwarder_enforcement" {
  description = "Event-forwarder required-workflow enforcement mode."
  type        = string
  default     = "evaluate"
  validation {
    condition     = contains(["disabled","evaluate","active"], var.event_forwarder_enforcement)
    error_message = "Use disabled, evaluate or active."
  }
}

# The fork approval policy gates the Default runner group's public reach.
variable "fork_pr_contributor_approval" {
  description = "Approval before fork PR workflows from contributors run: all_external_contributors is strictest; first_time_* values gate only contributors new to GitHub."
  type        = string
  default     = "all_external_contributors"

  validation {
    condition     = contains(["first_time_contributors_new_to_github", "first_time_contributors", "all_external_contributors"], var.fork_pr_contributor_approval)
    error_message = "fork_pr_contributor_approval: first_time_contributors_new_to_github, first_time_contributors, or all_external_contributors."
  }
}

variable "default_runner_group_allows_public_repositories" {
  description = <<-EOT
    Whether the Default runner group may serve public repositories; keep true only with the strictest fork approval policy.
  EOT
  type        = bool
  default     = true

  validation {
    condition     = !var.default_runner_group_allows_public_repositories || var.fork_pr_contributor_approval == "all_external_contributors"
    error_message = "default_runner_group_allows_public_repositories requires all_external_contributors fork approval"
  }
}
