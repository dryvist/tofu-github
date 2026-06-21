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
# org admins, so an admin's own commits are still signed, linear, and
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
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    required_linear_history = true
    required_signatures     = true

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
# to signed commits, linear history, or commit format. Any OrganizationAdmin
# can merge their own PRs without external review; non-admin actors (bots,
# external contributors) must obtain the review and, on critical files,
# a CODEOWNER review.
#
# bypass_mode = "pull_request": admins bypass on merge only, not on push.
# Pushes still satisfy every other rule (signed, linear, conventional).
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
    repository_name {
      include = ["~ALL"]
      exclude = []
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
