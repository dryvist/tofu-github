# Org-wide native push protection — max file size + banned extensions.
#
# Enforced at the git layer by GitHub's own push rules; no workflow runs.
# Thresholds and extension list come from config/rulesets-defaults.yml via
# local.push_protection_defaults, so this resource carries no magic numbers
# or hardcoded lists. Bypass actors are managed in the GitHub UI — this
# resource does not claim ownership of them, so manual exemptions for
# specific repos or actors persist across applies.
resource "github_organization_ruleset" "org_push_protection" {
  name        = "org-push-protection"
  target      = "push"
  enforcement = var.org_push_protection_enforcement

  conditions {
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    max_file_size {
      max_file_size = local.push_protection_defaults.max_file_size_mb
    }

    file_extension_restriction {
      restricted_file_extensions = local.push_protection_defaults.banned_file_extensions
    }
  }
}

# Org-wide branch-protection — quality rules on every default branch.
#
# Reverse-engineered from the pre-Terraform "main" org ruleset plus new
# directives: Conventional Commits enforcement and PR
# thread resolution. No bypass actors: rules apply to everyone including
# org admins, so an admin's own commits are still signed and
# Conventional-format. A separate imported ruleset below extends signature
# enforcement to every branch. Review-count enforcement lives in a separate
# ruleset (org_review_gate) so admin bypass on review doesn't accidentally
# weaken these quality gates.
#
# Import-on-first-apply: the import block below adopts the live ruleset
# into Terraform state so apply reconciles instead of creating a duplicate.
import {
  to = github_organization_ruleset.org_branch_protection
  id = local.ruleset_imports.org_branch_protection
}

resource "github_organization_ruleset" "org_branch_protection" {
  name        = "org-branch-protection"
  target      = "branch"
  enforcement = var.org_branch_protection_enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
    # Git-flow repos are excluded: their default branch is develop. Their main and
    # develop protection comes from the org-gitflow-* rulesets below instead.
    repository_property {
      exclude = [{
        name            = "gitflow"
        property_values = ["true"]
        source          = "custom"
      }]
    }
  }

  rules {
    required_signatures = true

    branch_name_pattern {
      operator = local.branch_protection_defaults.branch_name_operator
      pattern  = local.branch_protection_defaults.branch_name_pattern
      negate   = false
      name     = ""
    }

    commit_message_pattern {
      name     = "conventional-commits"
      operator = "regex"
      pattern  = local.branch_protection_defaults.commit_message_pattern
      negate   = false
    }

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
      allowed_merge_methods             = local.branch_protection_defaults.allowed_merge_methods
    }
  }
}

# Org-wide signature enforcement on every branch.
#
# This ruleset already exists live and is adopted without changing its
# behavior. Keeping it separate from default-branch protection preserves the
# broader all-branch coverage.
import {
  to = github_organization_ruleset.required_signatures
  id = local.ruleset_imports.required_signatures
}

resource "github_organization_ruleset" "required_signatures" {
  name        = "required_signatures"
  target      = "branch"
  enforcement = var.required_signatures_enforcement

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    required_signatures = true
  }
}

# Org-wide review gate — 1 approving review + CODEOWNER review on PRs.
#
# Separate ruleset (rather than rolled into org_branch_protection) so the
# OrganizationAdmin bypass below applies ONLY to review enforcement, not
# to signed commits or commit format. Any OrganizationAdmin
# can merge their own PRs without external review; non-admin actors (bots,
# external contributors) must obtain the review and, on critical files,
# a CODEOWNER review.
#
# bypass_mode = "pull_request": admins bypass on merge only, not on push.
# Pushes still satisfy every other rule (signed, conventional).
# Granting an additional account the OrganizationAdmin role extends this
# bypass to them — review the role assignments before adding admins.
resource "github_organization_ruleset" "org_review_gate" {
  name        = "org-review-gate"
  target      = "branch"
  enforcement = var.org_review_gate_enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
    # Git-flow repos are excluded so the review gate never binds develop (their
    # default branch), where direct pushes and back-merges must flow freely.
    # A gated main on a git-flow repo would be re-added by an org-gitflow-main
    # variant if/when this ruleset is enabled — today it is disabled by default.
    repository_property {
      exclude = [{
        name            = "gitflow"
        property_values = ["true"]
        source          = "custom"
      }]
    }
  }

  rules {
    pull_request {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = true
      require_last_push_approval        = false
      required_review_thread_resolution = true
      allowed_merge_methods             = local.branch_protection_defaults.allowed_merge_methods
    }
  }

  bypass_actors {
    # OrganizationAdmin role: actor_id = 1 is the only valid value for this
    # actor_type per the GitHub Rulesets API (a protocol constant, not a
    # tunable threshold). Every OrganizationAdmin bypasses review on merge.
    actor_id    = 1
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }
}

# Org-wide markdown linting, enforced as a Required Workflow.
#
# Adopts the existing disabled live ruleset so apply reconciles instead of
# creating a duplicate. `do_not_enforce_on_create` keeps brand-new repos from
# being blocked before their default branch exists. Enforcement defaults to
# the legacy `evaluate` posture; pass `-var markdown_lint_enforcement=active`
# to enforce.
import {
  to = github_organization_ruleset.markdown_lint
  id = local.ruleset_imports.markdown_lint
}

resource "github_organization_ruleset" "markdown_lint" {
  name        = "org-markdown-lint"
  target      = "branch"
  enforcement = var.markdown_lint_enforcement

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    required_workflows {
      do_not_enforce_on_create = true

      required_workflow {
        repository_id = data.github_repository.dot_github.repo_id
        path          = ".github/workflows/markdownlint.yml"
        ref           = "refs/heads/main"
      }
    }
  }
}

# Org-wide repo-conventions presence check, enforced as a Required Workflow.
#
# Injects the org `.github` repo's conventions-check.yml (presence of LICENSE,
# AGENTS.md, a Nix dev-shell entry, and a release-please config) into every
# repo's default-branch PRs. Mirrors markdown_lint's shape.
#
# SOFT ROLLOUT: this is a brand-new ruleset (no live import) and its
# enforcement defaults to "evaluate" (dry-run — reports in Rulesets > Insights
# without blocking merges), not the "active" default used for other new
# rulesets, because a large share of org repos currently lack AGENTS.md. The
# workflow itself also defaults to WARN (exit 0), so the check stays
# non-blocking on two independent levers until deliberately escalated.
# `do_not_enforce_on_create` keeps brand-new repos from being blocked before
# their default branch exists. Enforce with:
# `tofu apply -var conventions_enforcement=active`.
resource "github_organization_ruleset" "conventions" {
  name        = "org-conventions"
  target      = "branch"
  enforcement = var.conventions_enforcement

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    required_workflows {
      do_not_enforce_on_create = true

      required_workflow {
        repository_id = data.github_repository.dot_github.repo_id
        path          = ".github/workflows/conventions-check.yml"
        ref           = "refs/heads/main"
      }
    }
  }
}

# Git-flow `base` protection — common rules for main and develop.
#
# Binds local.gitflow_repos on both refs/heads/main and refs/heads/develop.
# Enforces required signatures on both branches in a single ruleset, as
# requested.
resource "github_organization_ruleset" "org_gitflow_base" {
  name        = "org-gitflow-base"
  target      = "branch"
  enforcement = var.org_gitflow_base_enforcement

  conditions {
    ref_name {
      include = ["refs/heads/main", "refs/heads/develop"]
      exclude = []
    }
    repository_property {
      include = [{
        name            = "gitflow"
        property_values = ["true"]
        source          = "custom"
      }]
    }
  }

  rules {
    required_signatures = true
  }
}

# Git-flow `main` protection — the release branch on opted-in repos.
#
# Binds only local.gitflow_repos (derived from `gitflow: true` in
# config/repos.yml) on the literal refs/heads/main — NOT ~DEFAULT_BRANCH, which
# now points at develop on these repos. main is release-only: PRs required (no
# direct pushes), merge-commit the sole merge method so release/hotfix history is
# preserved, PR threads must resolve, and commit messages match the
# Conventional-Commits-or-merge pattern. Signatures are enforced by
# org_gitflow_base (and the org-wide all-branch ruleset).
# These repos are excluded from org_branch_protection
# above, so this is their main-branch policy in full.
resource "github_organization_ruleset" "org_gitflow_main" {
  name        = "org-gitflow-main"
  target      = "branch"
  enforcement = var.org_gitflow_main_enforcement

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
    repository_property {
      include = [{
        name            = "gitflow"
        property_values = ["true"]
        source          = "custom"
      }]
    }
  }

  rules {
    commit_message_pattern {
      name     = "conventional-commits-or-merge"
      operator = "regex"
      pattern  = local.gitflow_defaults.commit_message_pattern
      negate   = false
    }

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
      allowed_merge_methods             = local.gitflow_defaults.main_allowed_merge_methods
    }
  }
}

# Git-flow `develop` protection — the integration branch on opted-in repos.
#
# Binds only local.gitflow_repos on the literal refs/heads/develop. develop is
# the integration branch: PRs required to enforce merge methods (squash, merge,
# rebase). The single commit rule is the
# Conventional-Commits-or-merge message pattern, keeping subject quality without
# rejecting "Merge branch ..." commits. Signatures come from the org-gitflow-base
# ruleset.
resource "github_organization_ruleset" "org_gitflow_develop" {
  name        = "org-gitflow-develop"
  target      = "branch"
  enforcement = var.org_gitflow_develop_enforcement

  conditions {
    ref_name {
      include = ["refs/heads/develop"]
      exclude = []
    }
    repository_property {
      include = [{
        name            = "gitflow"
        property_values = ["true"]
        source          = "custom"
      }]
    }
  }

  rules {
    commit_message_pattern {
      name     = "conventional-commits-or-merge"
      operator = "regex"
      pattern  = local.gitflow_defaults.commit_message_pattern
      negate   = false
    }

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
      allowed_merge_methods             = local.gitflow_defaults.develop_allowed_merge_methods
    }
  }
}

# Git-flow Copilot code review — automatic Copilot review on PRs into
# develop only (not main) for opted-in repos.
#
# develop-only, not org_gitflow_base's main+develop pattern: develop is the
# high-volume integration branch where feature PRs land; main on gitflow
# repos is release/hotfix-only and low-volume. Unlike the native rulesets
# above, Copilot review bills per review in AI credits — scoping to develop
# and setting review_on_push = false bound that to roughly one review per PR,
# on the branch that actually needs it.
resource "github_organization_ruleset" "org_gitflow_copilot_review" {
  name        = "org-gitflow-copilot-review"
  target      = "branch"
  enforcement = var.org_gitflow_copilot_review_enforcement

  conditions {
    ref_name {
      include = ["refs/heads/develop"]
      exclude = []
    }
    repository_property {
      include = [{
        name            = "gitflow"
        property_values = ["true"]
        source          = "custom"
      }]
    }
  }

  rules {
    copilot_code_review {
      review_on_push             = false
      review_draft_pull_requests = false
    }
  }
}
