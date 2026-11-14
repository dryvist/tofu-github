# Enforcement inputs accept disabled, evaluate, or active.
variable "markdown_lint_enforcement" {
  description = "Org markdown-lint enforcement; activate when the fleet is green."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.markdown_lint_enforcement)
    error_message = "markdown_lint_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "conventions_enforcement" {
  description = "Org repo-conventions presence checks; CONVENTIONS_STRICT opts repos into failure."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.conventions_enforcement)
    error_message = "conventions_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "ai_review_enforcement" {
  description = "Org-wide AI review on PRs via PR-Agent on the model router; active blocks merges through router outages."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.ai_review_enforcement)
    error_message = "ai_review_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "docs_publisher_enforcement" {
  description = "Documentation publisher approval count; release and triage apps bypass PRs."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.docs_publisher_enforcement)
    error_message = "docs_publisher_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_branch_protection_enforcement" {
  description = "Default-branch quality rules (signatures, branch pattern, Conventional Commits, thread resolution); no admin bypass."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_branch_protection_enforcement)
    error_message = "org_branch_protection_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "required_signatures_enforcement" {
  description = "Org-wide required-signatures rule on every branch."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.required_signatures_enforcement)
    error_message = "required_signatures_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_review_gate_enforcement" {
  description = "Default-branch review gate; OrganizationAdmin and release automation bypass in pull_request mode."
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_review_gate_enforcement)
    error_message = "org_review_gate_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_gitflow_base_enforcement" {
  description = "Git-flow base (local.gitflow_repos): signatures on main and develop."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_gitflow_base_enforcement)
    error_message = "Enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_gitflow_main_enforcement" {
  description = "Git-flow main ruleset: PRs only, merge commits, thread resolution, Conventional-Commits-or-merge."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_gitflow_main_enforcement)
    error_message = "org_gitflow_main_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_gitflow_develop_enforcement" {
  description = "Git-flow develop ruleset: PRs only, merge methods from rulesets-defaults.yml, Conventional-Commits-or-merge."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_gitflow_develop_enforcement)
    error_message = "org_gitflow_develop_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_release_freeze_enforcement" {
  description = "Git-flow repos require release-freeze on develop; activate after all git-flow repos call the status workflow."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_release_freeze_enforcement)
    error_message = "org_release_freeze_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_copilot_review_enforcement" {
  description = "Copilot review on targets listed in selected copilot-review.yml; paid, one review per PR."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_copilot_review_enforcement)
    error_message = "org_copilot_review_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_push_protection_enforcement" {
  description = "Native file-size and banned-extension push rules on every repo/ref, no workflow runs."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_push_protection_enforcement)
    error_message = "org_push_protection_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_code_scanning_enforcement" {
  description = "Require CodeQL default-setup results on public repos; evaluate until every target repo has an analysis."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_code_scanning_enforcement)
    error_message = "org_code_scanning_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "codeql_import_enabled" {
  description = "Adopt existing CodeQL default-setup configuration via the import block."
  type        = bool
  default     = true
}

variable "org_merge_gate_enforcement" {
  description = "org-merge-gate-* required checks on main; each selected repo needs a live gate context first."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_merge_gate_enforcement)
    error_message = "org_merge_gate_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "merge_gate_strict_enforcement" {
  description = "org-merge-gate-strict-* required checks require PRs up to date with base; evaluate reports."
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.merge_gate_strict_enforcement)
    error_message = "merge_gate_strict_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_upstream_fork_protection_enforcement" {
  description = "Upstream forks: default branch requires PRs and merge commits; deletion and force-push forbidden."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_upstream_fork_protection_enforcement)
    error_message = "org_upstream_fork_protection_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_branch_write_restriction_enforcement" {
  description = "Blocks actors outside automation_bypass_app_ids from creating/updating branches except main."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_branch_write_restriction_enforcement)
    error_message = "org_branch_write_restriction_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "automation_bypass_app_ids" {
  description = "Required: GitHub App IDs allowed to write restricted branches; list every branch-writer to avoid lockouts."
  type        = list(number)

  validation {
    condition     = length(var.automation_bypass_app_ids) > 0
    error_message = "automation_bypass_app_ids must list at least one GitHub App ID."
  }
}

# Self-hosted review runners register into the pr-agent runner group, which
# only sends jobs to the workflows listed here. The review workflow lives in a
# repository selected per workspace outside this repository.
variable "review_runner_selected_workflows" {
  description = "Required: workflow refs (org/repo/.github/workflows/file.yml@ref) that may send jobs to the pr-agent runner group; every review workflow must be listed or its jobs find no runner."
  type        = list(string)

  validation {
    condition = length(var.review_runner_selected_workflows) > 0 && alltrue([
      for workflow in var.review_runner_selected_workflows :
      can(regex("^[^/]+/[^/]+/\\.github/workflows/[^@]+@.+$", workflow))
    ])
    error_message = "review_runner_selected_workflows must list at least one org/repo/.github/workflows/file.yml@ref."
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

variable "org_automerge_manual_enforcement" {
  description = "Enforces automerge=manual review: one approval on main/develop; OrganizationAdmin, agent, triage, and release apps bypass."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_automerge_manual_enforcement)
    error_message = "org_automerge_manual_enforcement must be one of: disabled, evaluate, active."
  }
}

# Hermes PR-review webhook sends pull_request events; created when both variables are set.
variable "hermes_webhook_url" {
  description = "Hermes PR-review intake URL; empty skips the webhook."
  type        = string
  sensitive   = true
  default     = ""
}

variable "hermes_webhook_secret" {
  description = "GitHub HMAC signing secret; empty skips the webhook."
  type        = string
  sensitive   = true
  default     = ""
}

# Event queue intake for check_run and pull_request events; off until the
# intake records exist in Vault so the plan never reads absent paths.
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
    condition     = contains(["disabled", "evaluate", "active"], var.event_forwarder_enforcement)
    error_message = "Use disabled, evaluate or active."
  }
}
