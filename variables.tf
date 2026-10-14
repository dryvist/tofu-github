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

variable "markdown_lint_enforcement" {
  description = <<-EOT
    Enforcement mode for the org-wide markdown-lint ruleset.

    Start at "evaluate" (dry-run): the ruleset reports results in the org
    Rulesets > Insights tab WITHOUT blocking any merges. This lets the rule roll
    out across every repo safely before the whole org's markdown is compliant.
    Flip to "active" once Insights shows the fleet is green.
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
    Enforcement mode for the org-wide AI review ruleset, which injects the
    `ai-review.yml` workflow from the org's `.github` repo into every repo's
    pull requests. It runs PR-Agent on the model router.

    Defaults to "evaluate": every pull request is reviewed and the outcome is
    reported, but does not gate the merge. "active" gates the merge instead —
    the workflow waits through a router outage and then fails rather than
    passing empty, so an outage blocks merges until it clears.
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
    Enforcement mode for the public documentation publisher ruleset. The
    ruleset requires the org provenance workflow and configured approval
    count, with pull-request bypasses for release automation and triage apps.
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
    Enforcement mode for the org-wide branch-protection ruleset on default
    branches. Quality rules — required signatures, branch
    name pattern, Conventional Commits commit messages, PR thread
    resolution. NO bypass actors: applies to everyone, so admin-authored
    commits get the same quality gates as everyone else.

    Defaults to the pre-Terraform live state of the imported ruleset.
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
    OrganizationAdmin and the release automation app bypass review in
    `pull_request` mode; other non-bypass actors must obtain the review.
    Defaults to "disabled".
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

    Set to "disabled" with `-var` to switch off a misbehaving rule without a code change.
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

    Set to "disabled" with `-var` if it gets in the way during the pilot.
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
    Enforcement mode for the release-freeze required status check on the
    develop branch of git-flow repos. It defaults to "evaluate" so the rule
    reports without blocking merges. Set it to "active" once the shared status
    workflow is called from every git-flow repo.
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
    Enforcement mode for the Copilot code-review pilot ruleset(s) --
    explicit (branch, repo-list) targets from the selected copilot-review.yml,
    not a property match. Growing the pilot is a config edit there, never
    a variable change here.

    Cost note: unlike the native rulesets in this repo, Copilot code review
    bills AI credits directly per review (0 assigned Copilot seats, so no
    pooled allowance) -- it is the one ruleset here that costs money to
    run. review_on_push = false caps it at roughly one review per PR.
    Current rates and usage headroom are point-in-time facts that belong
    in the PR that changes the target list, not in this description.

    Set to "disabled" with `-var` to stop the spend without a code change.
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
    Enforcement mode for the org-wide push-protection ruleset (native
    max_file_size + file_extension_restriction push rules). Applies to every
    repo, every ref; enforced at the git layer with no workflow runs.

    Set to "disabled" with `-var` to switch off a misbehaving rule without a code change.
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
    Merge Gate check succeeds. Every repo listed in the selected merge-gate.yml
    must have its gate context live on main BEFORE this is active — a
    required check that never reports freezes the repo's PRs.
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
    Enforcement mode for the default-branch ruleset on upstream forks (repos
    with `upstream_fork: true`): pull request required, merge commits only,
    no deletion or force-push.
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
    Enforcement mode for the org-wide branch-write restriction ruleset
    (rulesets-branch-write-restriction.tf). "active" stops every actor
    outside var.automation_bypass_app_ids from creating or updating any
    branch except main.

    Set to "disabled" with `-var` to switch the rule off without a code change.
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
    GitHub App IDs allowed to create and update branches that the
    branch-write restriction covers. Supplied by the operator as a workspace
    variable; there is no default, so the ruleset cannot apply with an empty
    bypass list and lock out every automation. Include every app that opens
    or updates branches: the Actions app, the dependency-update app, the
    release app and the org's own automation apps.
  EOT
  type        = list(number)

  validation {
    condition     = length(var.automation_bypass_app_ids) > 0
    error_message = "automation_bypass_app_ids must list at least one GitHub App ID."
  }
}
