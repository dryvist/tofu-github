# Upstream forks.
#
# A repo opts in with `upstream_fork: true` in config/repos.yml. Such a repo is
# a fork of a third-party project whose default branch merges upstream's
# default branch on a schedule. Upstream commits are authored outside the org:
# they are mostly unsigned and do not follow Conventional Commits, so the
# org's signature and commit-format rulesets would reject every sync. Those
# rulesets exclude this property, and the ruleset below keeps the rest of the
# default-branch protection: changes arrive by pull request, merge commits
# only, and the branch cannot be deleted or force-pushed.
locals {
  upstream_fork_repos = [for name, cfg in local.repos : name if try(cfg.upstream_fork, false)]
}

resource "github_organization_custom_properties" "upstream_fork" {
  property_name = "upstream_fork"
  value_type    = "true_false"
}

resource "github_repository_custom_property" "upstream_fork" {
  for_each = toset(local.upstream_fork_repos)

  repository     = each.value
  property_name  = github_organization_custom_properties.upstream_fork.property_name
  property_type  = "true_false"
  property_value = ["true"]
}

resource "github_organization_ruleset" "org_upstream_fork_protection" {
  name        = "org-upstream-fork-protection"
  target      = "branch"
  enforcement = var.org_upstream_fork_protection_enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
    repository_property {
      include = [{
        name            = github_organization_custom_properties.upstream_fork.property_name
        property_values = ["true"]
        source          = "custom"
      }]
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    branch_name_pattern {
      operator = local.branch_protection_defaults.branch_name_operator
      pattern  = local.branch_protection_defaults.branch_name_pattern
      negate   = false
      name     = ""
    }

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
      allowed_merge_methods             = local.upstream_fork_defaults.allowed_merge_methods
    }
  }
}
