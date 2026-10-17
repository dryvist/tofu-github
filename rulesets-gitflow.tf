# Git-flow `base` protection — common rules for main and develop.
#
# Binds local.gitflow_repos on both refs/heads/main and refs/heads/develop.
# Enforces required signatures, and blocks branch deletion and non-fast-forward
# (force) pushes, on both branches in a single ruleset, as requested.
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
    deletion            = true
    non_fast_forward    = true
  }
}

# Git-flow `main` protection — the release branch on opted-in repos.
#
# Binds only local.gitflow_repos (derived from `gitflow: true` in the selected
# per-org repos.yml) on the literal refs/heads/main — NOT ~DEFAULT_BRANCH, which
# now points at develop on these repos. main is release-only: PRs required (no
# direct pushes), merge-commit the sole merge method so release/hotfix history is
# preserved, PR threads must resolve, and commit messages match the
# Conventional-Commits-or-merge pattern. Signatures are enforced by
# org_gitflow_base (and the org-wide all-branch ruleset).
# These repos are excluded from org_branch_protection
# above, so this is their main-branch policy in full.
removed {
  from = github_organization_ruleset.org_gitflow_main

  lifecycle {
    destroy = false
  }
}

import {
  for_each = try(local.ruleset_imports.org_gitflow_main, null) == null ? {} : { existing = local.ruleset_imports.org_gitflow_main }
  to       = restapi_object.org_gitflow_main
  id       = "/orgs/${var.github_owner}/rulesets/${each.value}"
}

resource "restapi_object" "org_gitflow_main" {
  path         = "/orgs/${var.github_owner}/rulesets"
  id_attribute = "id"
  # Fields GitHub adds to a ruleset response; they never appear in the request body.
  ignore_changes_to = ["_links", "created_at", "id", "node_id", "source", "source_type", "updated_at"]

  data = jsonencode({
    name          = "org-gitflow-main"
    target        = "branch"
    enforcement   = var.org_gitflow_main_enforcement
    bypass_actors = []
    conditions = {
      ref_name = {
        include = ["refs/heads/main"]
        exclude = []
      }
      repository_property = {
        include = [{
          name            = "gitflow"
          property_values = ["true"]
          source          = "custom"
        }]
        exclude = []
      }
    }
    rules = [
      {
        type = "pull_request"
        parameters = merge(local.pull_request_rule_base, {
          required_approving_review_count   = 0
          dismiss_stale_reviews_on_push     = false
          require_code_owner_review         = false
          require_last_push_approval        = false
          required_review_thread_resolution = true
          allowed_merge_methods             = local.gitflow_defaults.main_allowed_merge_methods
        })
      },
      {
        type = "commit_message_pattern"
        parameters = {
          name     = "conventional-commits-or-merge"
          operator = "regex"
          pattern  = local.gitflow_commit_message_pattern
          negate   = false
        }
      },
    ]
  })
}

# Git-flow `develop` protection — the integration branch on opted-in repos.
#
# Binds only local.gitflow_repos on the literal refs/heads/develop. develop is
# the integration branch: PRs only, merge methods from config. The single commit rule is the
# Conventional-Commits-or-merge message pattern, keeping subject quality without
# rejecting "Merge branch ..." commits. Signatures come from the org-gitflow-base
# ruleset.
removed {
  from = github_organization_ruleset.org_gitflow_develop

  lifecycle {
    destroy = false
  }
}

import {
  for_each = try(local.ruleset_imports.org_gitflow_develop, null) == null ? {} : { existing = local.ruleset_imports.org_gitflow_develop }
  to       = restapi_object.org_gitflow_develop
  id       = "/orgs/${var.github_owner}/rulesets/${each.value}"
}

resource "restapi_object" "org_gitflow_develop" {
  path         = "/orgs/${var.github_owner}/rulesets"
  id_attribute = "id"
  # Fields GitHub adds to a ruleset response; they never appear in the request body.
  ignore_changes_to = ["_links", "created_at", "id", "node_id", "source", "source_type", "updated_at"]

  data = jsonencode({
    name          = "org-gitflow-develop"
    target        = "branch"
    enforcement   = var.org_gitflow_develop_enforcement
    bypass_actors = []
    conditions = {
      ref_name = {
        include = ["refs/heads/develop"]
        exclude = []
      }
      repository_property = {
        include = [{
          name            = "gitflow"
          property_values = ["true"]
          source          = "custom"
        }]
        exclude = []
      }
    }
    rules = [
      {
        type = "commit_message_pattern"
        parameters = {
          name     = "conventional-commits-or-merge"
          operator = "regex"
          pattern  = local.gitflow_commit_message_pattern
          negate   = false
        }
      },
      {
        type = "pull_request"
        parameters = merge(local.pull_request_rule_base, {
          required_approving_review_count   = 0
          dismiss_stale_reviews_on_push     = false
          require_code_owner_review         = false
          require_last_push_approval        = false
          required_review_thread_resolution = true
          allowed_merge_methods             = local.gitflow_defaults.develop_allowed_merge_methods
        })
      },
    ]
  })
}
