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
