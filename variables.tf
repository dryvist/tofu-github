# Enforcement inputs accept disabled, evaluate, or active.
variable "markdown_lint_enforcement" {
  description = <<-EOT
    Org markdown-lint enforcement. Evaluate reports in Insights without blocking; activate when the fleet is green.
  EOT
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.markdown_lint_enforcement)
    error_message = "markdown_lint_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "conventions_enforcement" {
  description = <<-EOT
    Org repo-conventions presence checks: LICENSE, AGENTS.md, Nix dev shell, release-please config. Evaluate reports without blocking; workflow defaults to WARN (exit 0). CONVENTIONS_STRICT repo variable opts repos into failure; activate when Insights shows the fleet is green.
  EOT
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.conventions_enforcement)
    error_message = "conventions_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "ai_review_enforcement" {
  description = <<-EOT
    Org-wide AI review injects .github/ai-review.yml into every repo's PRs and runs PR-Agent on the model router. Evaluate reports without gating; active waits through a router outage, then fails and blocks merges.
  EOT
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.ai_review_enforcement)
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
    condition     = contains(["disabled", "evaluate", "active"], var.docs_publisher_enforcement)
    error_message = "docs_publisher_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_branch_protection_enforcement" {
  description = <<-EOT
    Default-branch rules require signatures, branch-name pattern, Conventional Commit messages, and PR thread resolution; no bypass, including for admins.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_branch_protection_enforcement)
    error_message = "org_branch_protection_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "required_signatures_enforcement" {
  description = <<-EOT
    Org-wide required-signatures rule covers every branch.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.required_signatures_enforcement)
    error_message = "required_signatures_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_review_gate_enforcement" {
  description = <<-EOT
    Default-branch gate requires one approval and CODEOWNER review; OrganizationAdmin and release automation bypass in pull_request mode, all others need review.
  EOT
  type        = string
  default     = "disabled"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_review_gate_enforcement)
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
    condition     = contains(["disabled", "evaluate", "active"], var.org_gitflow_base_enforcement)
    error_message = "Enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_gitflow_main_enforcement" {
  description = <<-EOT
    Git-flow main applies only to local.gitflow_repos: PRs (no direct pushes), merge commits only, thread resolution, and Conventional-Commits-or-merge messages; signatures are enforced by org-gitflow-base and org-wide rulesets.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_gitflow_main_enforcement)
    error_message = "org_gitflow_main_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_gitflow_develop_enforcement" {
  description = <<-EOT
    Git-flow develop applies only to local.gitflow_repos: PRs (no direct pushes), merge methods from config/rulesets-defaults.yml. Its only rule is the Conventional-Commits-or-merge message pattern, so main back-merges and conventional feature-squash subjects pass; signatures are enforced by org-gitflow-base and org-wide rulesets.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_gitflow_develop_enforcement)
    error_message = "org_gitflow_develop_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_release_freeze_enforcement" {
  description = <<-EOT
    Git-flow repos require the release-freeze status check on develop. Evaluate reports without blocking; activate after every git-flow repo calls the shared status workflow.
  EOT
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_release_freeze_enforcement)
    error_message = "org_release_freeze_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_copilot_review_enforcement" {
  description = <<-EOT
    Pilot targets explicit branches and repos in selected copilot-review.yml, not property matches; expand it there. Paid: AI credits per review, no seats or pooled allowance; review_on_push=false caps about one review per PR.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_copilot_review_enforcement)
    error_message = "org_copilot_review_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_push_protection_enforcement" {
  description = <<-EOT
    Native max_file_size and file_extension_restriction rules cover every repo/ref at the git layer, without workflow runs.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_push_protection_enforcement)
    error_message = "org_push_protection_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_code_scanning_enforcement" {
  description = "Require CodeQL default-setup results on public repositories' default branch and main before updates."
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_code_scanning_enforcement)
    error_message = "org_code_scanning_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "codeql_import_enabled" {
  description = <<-EOT
    Controls whether code_scanning.tf adopts existing CodeQL default-setup configuration through its import block.
  EOT
  type        = bool
  default     = true
}

variable "org_merge_gate_enforcement" {
  description = <<-EOT
    org-merge-gate-* required checks block merges to main; each selected repo needs a live gate context on main before activation or its PRs freeze.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_merge_gate_enforcement)
    error_message = "org_merge_gate_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_upstream_fork_protection_enforcement" {
  description = <<-EOT
    For upstream_fork=true, default branch requires PRs and merge commits; deletion and force-push are forbidden.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_upstream_fork_protection_enforcement)
    error_message = "org_upstream_fork_protection_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_branch_write_restriction_enforcement" {
  description = <<-EOT
    Org-wide active branch-write restriction blocks actors outside var.automation_bypass_app_ids from creating/updating branches except main.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_branch_write_restriction_enforcement)
    error_message = "org_branch_write_restriction_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "automation_bypass_app_ids" {
  description = <<-EOT
    Required workspace list with no default: GitHub App IDs allowed to create/update branches covered by the restriction. Non-empty avoids locking out all automation; include every branch-writer (Actions, dependency-update, release, and org apps).
  EOT
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
  description = <<-EOT
    Enforces automerge=manual review: one approval on main/develop; OrganizationAdmin, configured agent, triage, and release apps bypass.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_automerge_manual_enforcement)
    error_message = "org_automerge_manual_enforcement must be one of: disabled, evaluate, active."
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
