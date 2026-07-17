variable "markdown_lint_enforcement" {
  description = <<-EOT
    Enforcement mode for the org-wide markdown-lint ruleset.

    Start at "evaluate" (dry-run): the ruleset reports results in the org
    Rulesets > Insights tab WITHOUT blocking any merges. This lets the rule roll
    out across every repo safely before the whole org's markdown is compliant.
    Flip to "active" once Insights shows the fleet is green.

    One of: disabled, evaluate, active.
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
    Enforcement mode for the org-wide repo-conventions presence ruleset
    (LICENSE, AGENTS.md, a Nix dev-shell entry, and a release-please config).

    Defaults to "evaluate" (dry-run): the ruleset reports results in the org
    Rulesets > Insights tab WITHOUT blocking any merges, and the injected
    workflow additionally defaults to WARN (exit 0). This double-soft posture
    lets the rule roll out across every repo without breaking the many that
    are not yet compliant. Escalation path: repos opt in to hard failure via
    the CONVENTIONS_STRICT repository variable, then flip this to "active"
    once Insights shows the fleet is green.

    One of: disabled, evaluate, active.
  EOT
  type        = string
  default     = "evaluate"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.conventions_enforcement)
    error_message = "conventions_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_branch_protection_enforcement" {
  description = <<-EOT
    Enforcement mode for the org-wide branch-protection ruleset on default
    branches. Quality rules — required signatures, branch
    name pattern, Conventional Commits commit messages, PR thread
    resolution. NO bypass actors: applies to everyone, so admin-authored
    commits get the same quality gates as everyone else.

    One of: disabled, evaluate, active. Defaults to "active" — matches the
    pre-Terraform live enforcement state of the imported ruleset.
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
    Enforcement mode for the org-wide required-signatures ruleset on every
    branch. This preserves the all-branch coverage of the imported live
    ruleset.

    One of: disabled, evaluate, active. Defaults to "active" to match live.
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
    Enforcement mode for the org-wide review-gate ruleset on default
    branches. Requires 1 approving review + CODEOWNER review on PRs.
    Bypass actor: OrganizationAdmin in `pull_request` mode — any account
    holding the OrganizationAdmin role can merge their own PRs without
    external review. Non-admin actors (bots, external contributors) must
    obtain the review.

    Defaults to "disabled": this is a single-operator org today, so required
    reviews only get in the way. The ruleset stays DEFINED as the documented
    future-state placeholder — flip to "active" with `-var` (or change this
    default) once AI bots merge as separate non-admin users that must be gated.

    One of: disabled, evaluate, active.
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
    Enforcement mode for the git-flow `base` ruleset. Binds the repos opted into
    git-flow (local.gitflow_repos) on refs/heads/main and refs/heads/develop.
    Enforces required signatures for both branches in a single ruleset.

    One of: disabled, evaluate, active. Defaults to "active" — new rulesets
    enforce directly.
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
    Enforcement mode for the git-flow `main` ruleset. Binds only the repos
    opted into git-flow (local.gitflow_repos) on refs/heads/main: PRs required
    (no direct pushes), merge-commit the only allowed merge method, PR thread
    resolution, and a Conventional-Commits-or-merge message pattern.
    Signatures come from the org-gitflow-base ruleset (and org-wide).
    ruleset.

    One of: disabled, evaluate, active. Defaults to "active" — new rulesets
    apply enabled per the convention; the variable exists so a misbehaving rule
    can be disabled with `-var` without a code change.
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
    Enforcement mode for the git-flow `develop` ruleset. Binds only the repos
    opted into git-flow (local.gitflow_repos) on refs/heads/develop. develop is
    the integration branch: PRs required (no direct pushes) to enforce
    merge methods (squash, merge, rebase).
    The only rule is the Conventional-Commits-or-merge message pattern, so back-
    merges from main land cleanly while feature-squash subjects stay conventional.
    Signatures come from the org-gitflow-base ruleset (and org-wide).

    One of: disabled, evaluate, active. Defaults to "active"; disable with `-var`
    if it gets in the way during the pilot.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_gitflow_develop_enforcement)
    error_message = "org_gitflow_develop_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_gitflow_copilot_review_enforcement" {
  description = <<-EOT
    Enforcement mode for automatic Copilot code review on git-flow repos'
    develop branch only (not main, which is release-only and low-volume).
    Binds only local.gitflow_repos via the gitflow custom property.

    Cost note: unlike the native rulesets in this repo, Copilot code review
    bills per review in AI credits — it is the one ruleset here that costs
    money to run. review_on_push = false caps it at roughly one review per
    PR. Current rates and the org's seat position are point-in-time facts
    that belong in the PR that changes them, not in this description.

    One of: disabled, evaluate, active. Defaults to "active" — new rulesets
    apply enabled per the convention; set to "disabled" with `-var` to stop
    the spend without a code change.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_gitflow_copilot_review_enforcement)
    error_message = "org_gitflow_copilot_review_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_push_protection_enforcement" {
  description = <<-EOT
    Enforcement mode for the org-wide push-protection ruleset (native
    max_file_size + file_extension_restriction push rules). Applies to every
    repo, every ref; enforced at the git layer with no workflow runs.

    One of: disabled, evaluate, active. Defaults to "active" — new rulesets
    apply enabled directly per the convention; the variable exists so a
    misbehaving rule can be disabled with `-var` without a code change.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_push_protection_enforcement)
    error_message = "org_push_protection_enforcement must be one of: disabled, evaluate, active."
  }
}

variable "org_merge_gate_enforcement" {
  description = <<-EOT
    Enforcement mode for the org-merge-gate-* required-check rulesets
    (merge-gate.tf). "active" blocks merging into main until the repo's
    Merge Gate check succeeds. Every repo listed in config/merge-gate.yml
    must have its gate context live on main BEFORE this is active — a
    required check that never reports freezes the repo's PRs.

    One of: disabled, evaluate, active.
  EOT
  type        = string
  default     = "active"

  validation {
    condition     = contains(["disabled", "evaluate", "active"], var.org_merge_gate_enforcement)
    error_message = "org_merge_gate_enforcement must be one of: disabled, evaluate, active."
  }
}
