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

variable "org_branch_protection_enforcement" {
  description = <<-EOT
    Enforcement mode for the org-wide branch-protection ruleset on default
    branches. Quality rules — required signatures, linear history, branch
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

variable "org_gitflow_main_enforcement" {
  description = <<-EOT
    Enforcement mode for the git-flow `main` ruleset. Binds only the repos
    opted into git-flow (local.gitflow_repos) on refs/heads/main: PRs required
    (no direct pushes), merge-commit the only allowed merge method, PR thread
    resolution, and a Conventional-Commits-or-merge message pattern. Linear
    history is deliberately NOT required here — release/hotfix merges land as
    merge commits. Signatures still come from the org-wide required_signatures
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
    the permissive integration branch: direct pushes ALLOWED (no PR requirement),
    no linear-history requirement, and merge methods governed by repo settings.
    The only rule is the Conventional-Commits-or-merge message pattern, so back-
    merges from main land cleanly while feature-squash subjects stay conventional.
    Signatures still come from the org-wide required_signatures ruleset.

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
