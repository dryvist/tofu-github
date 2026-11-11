# Required `merge-hold` status, posted at every pull request head by the PR
# Reconcile controller (failure while the PR carries the merge-hold label).
# Only an organization with config/orgs/<owner>/merge-hold.yml gets the ruleset;
# `evaluate` reports the requirement without blocking, `active` enforces it.
# Enforce only after the controller's sweep covers every listed repository, or
# their pull requests wait for a status that never comes.
resource "github_organization_ruleset" "merge_hold" {
  count       = local.merge_hold_config == null ? 0 : 1
  name        = "org-merge-hold"
  target      = "branch"
  enforcement = local.merge_hold_enforcement

  lifecycle {
    precondition {
      condition     = contains(["disabled", "evaluate", "active"], local.merge_hold_enforcement) && length(local.merge_hold_repos) > 0
      error_message = "config/orgs/<owner>/merge-hold.yml needs enforcement disabled, evaluate or active, and a non-empty repos list."
    }
  }

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
    repository_name {
      include = local.merge_hold_repos
      exclude = []
    }
  }

  rules {
    required_status_checks {
      strict_required_status_checks_policy = false
      do_not_enforce_on_create             = true

      required_check {
        context = "merge-hold"
      }
    }
  }
}
